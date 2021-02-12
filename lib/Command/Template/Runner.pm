package Command::Template::Runner;
use strict;
use warnings;
use Command::Template::RunRecord;
use IPC::Run ();

sub last_run { return $_[0]{last_run} }

sub __ipc_run {
   my ($command, %options) = @_;
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

sub _handler {
   my ($self, $field, $new) = @_;
   return $self->{$field} unless defined $new;
   $self->{$field} = $new;
   return $self;
}

sub options { my $self = shift; $self->_handler(options => @_) }

sub run {
   my ($self, %bindopts) = @_;
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

sub template { my $self = shift; $self->_handler(template => @_) }

1;
