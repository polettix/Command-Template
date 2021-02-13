package Command::Template::Runner;
use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

use Command::Template::RunRecord;
use IPC::Run ();

sub last_run ($self) { return $self->{last_run} }

sub __ipc_run ($command, %options) {
   my $in = $options{stdin} // '';
   my $out = '';
   my $err = '';
   my $timeout = $options{timeout} // 0;

   my @args = ($command, \$in, \$out, \$err);
   push @args, IPC::Run::timeout($timeout) if $timeout;

   eval {
      IPC::Run::run(@args);
      $timeout = 0;
      1;
   } or do { die $@ if $@ !~ m{^IPC::Run:\s*timeout} };

   return {
      command => $command,
      ec      => $?,
      options => \%options,
      stderr  => $err,
      stdout  => $out,
      timeout => $timeout,
   };
}

sub _handler ($self, $field, $new = undef) {
   return $self->{$field} unless defined $new;
   $self->{$field} = $new;
   return $self;
}

sub options ($self, @rest) { $self->_handler(options => @rest) }

sub run ($self, %bindopts) {
   my (%bindings, %options);
   while (my ($key, $value) = each %bindopts) {
      if (substr($key, 0, 1) eq '-') {
         $options{substr $key, 1} = $value;
      }
      else {
         $bindings{$key} = $value;
      }
   }
   my $command = $self->{template}->command(%bindings);
   %options = (%{$self->options}, %options);
   my $retval = $self->{last_run} =
      bless __ipc_run($command, %options), 'Command::Template::RunRecord';
   return $retval;
}

sub template ($self, @rest) { $self->_handler(template => @rest) }

1;
