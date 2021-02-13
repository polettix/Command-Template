package Command::Template::Instance;
use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

sub defaults {
   my ($self, $new) = @_;
   $self->{defaults} = $new if defined $new;
   return defined $new ? $self : $self->{defaults};
}

sub command {
   my ($self, %bindings) = @_;
   my $defaults = $self->defaults;
   my @command;
   for my $arg (@{$self->{command}}) {
      if (! ref $arg) {
         push @command, $arg;
         next;
      }

      my ($name, $default, $type) = @{$arg}{qw< name default type >};
      my $value =
           exists $bindings{$name}   ? $bindings{$name}
         : exists $defaults->{$name} ? $defaults->{$name}
         : defined $default          ? $default
         :                             undef;
      if (defined $value) {
         push @command, ref($value) eq 'ARRAY' ? (@$value) : $value;
         next;
      }
      die "missing required parameter '$name'\n" if $type eq 'req';
   }
   return \@command;
} ## end sub expand

1;
