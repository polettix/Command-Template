package Command::Template;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw< command_runner command_template cr ct >;

our $InstanceClass = 'Command::Template::Instance';
our $RunnerClass   = 'Command::Template::Runner';

sub _parse_command {
   my @command;
   for my $arg (@_) {
      die "invalid parameter: undefined\n" unless defined $arg;
      die "invalid parameter: plain scalars only\n" if ref $arg;

      if (length($arg) == 0) {
         push @command, '';
         next;
      }

      my $first_char = substr $arg, 0, 1;
      if ($first_char eq '\\') {
         push @command, substr $arg, 1;
         next;
      }
      elsif ($first_char ne '<' && $first_char ne '[') {
         push @command, $arg;
         next;
      }

      my ($type, $lc) = $first_char eq '<' ? ('req', '>') : ('opt', ']');
      my ($name, $default) = $arg =~ m{
         \A \Q$first_char\E
            ([a-zA-Z_]\w+)  # name, starts with no digit
            (?: = (.*))?   # optional default value
         \Q$lc\E \z
      }mxs or die "invalid parameter {$arg}\n";
      push @command,
        {
         default => $default,
         name    => $name,
         type    => $type,
        };
   } ## end for my $arg (@_)

   return \@command;
} ## end sub _parse_command

sub _create {
   my $class  = _class(shift(@_));
   my $object = bless shift(@_), $class;
   $object->{command} = _parse_command(@_);
   return $object;
} ## end sub _create

sub _class {
   my ($class) = @_;
   (my $path = "$class.pm") =~ s{::}{/}gmxs;
   require $path;
   return $class;
}

sub command_runner {
   bless {template => ct(@_), options => {}}, _class($RunnerClass);
}

sub command_template { _create($InstanceClass, {defaults => {}}, @_) }

{
   no strict 'refs';
   *cr = *command_runner;
   *ct = *command_template;
}

1;
