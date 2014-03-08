use strict;
use warnings;
package Util::Timeout;
use POSIX qw{ceil};
use Exporter::Declare::Magic;
use Sys::SigAction qw{timeout_call};
use Devel::Declare::Parser::Sublike;

# ABSTRACT: thin wrapper around Sys::SigAction::timeout_call

=head1 NAME

Util::Timeout - thin wrapper around Sys::SigAction::timeout_call

=head1 SYNOPSIS 

  use Util::Timeout;
  timeout $seconds { ... } or do { ... };

  retry $times { ... } or do { ... };

=head1 DESCRIPTION 

Sys::SigAction::timeout_call sets a timer for $seconds, if your code block is still running when the 
timer trips then it is killed off. timeout then returns a false value thus you can chain with 'or'
to allow for a clean syntaticaly correct syntax

=head1 FUNCTIONS

=head2 timeout

  timeout 1 { sleep(2) } or do { $error = 'timed out' };

REMEMBER: these are lexical blocks (like eval) so any vars that you want to use else where will
need to be scoped as such.

Also note, due to alarm not allowing for decimal numbers, all values are rounded up. Any value given
for $seconds that is <= 0 will shortcut and your code block will not be executed and 0 returned.

=cut

default_export timeout sublike { 
   my ($seconds, $code) = @_;
   $seconds = ceil($seconds);
   return 0 unless $seconds > 0;
   return 0 unless defined $code && ref($code) eq 'CODE';
   # invert return to allow the use of 'or'
   !timeout_call( $seconds, $code ); # 0 => timed out
}

=head2 retry

  my $num = 3; 
  retry 5 { timeout 1 { sleep( $num-- ) } } or do { $error = 'timed out 5 times' };

retry will run your the code block, if the block returns true then we stop running and return '1'. 
If your code block returns false then it is run again, up to $times number of times (5 in the 
exampele), in this case rerun returns '0' allowing you to use 'or' like with timeout.

$times is expeceted to be an int, any decimal value will be rounded up. If $times is <= 1 then
your code block will not be run and 0 will be returned;

=cut

default_export retry sublike {
   my ($times, $code) = @_;
   $times = ceil($times);
   return 0 unless $times >= 1;
   for (1..$times) {
      return 1 if &$code;
   }
   return 0;
}

1;

=head1 REPOSITORY

L<https://github.com/notbenh/Util-Timeout>

=head1 AUTHOR

Ben Hengst E<lt>notbenh@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ben Hengst E<lt>notbenh@cpan.org<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


