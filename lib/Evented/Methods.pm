#
# Copyright (c) 2013, Mitchell Cooper
#
# Evented::Methods: the name says it all.
#
# Evented::Methods can be found in its latest version at
# https://github.com/cooper/evented-methods.
#
#
package Evented::Methods;

use warnings;
use strict;
use utf8;
use 5.010;

use Carp;
use Scalar::Util 'blessed';

our $VERSION = 0.1;
our %p;       # %p = package options

# Evented::Methods import subroutine.
sub import {
    my ($class, @opts) = @_;
    my $package = caller;
    
    # store Evented::Methods options.
    $p{$package}{desired} = \@opts;
    
    # determine methods.
    my (%methods, $last_thing);
    foreach my $thing (@opts) {
        if (ref $thing && ref $thing eq 'HASH') { $methods{$last_thing} = $thing }
        else { $methods{$thing} = {} }
        $last_thing = $thing;
    }
    
    # add each method.
    add_method($package, $_, %{ $methods{$_} }) foreach keys %methods;
    
    return 1;
}

# adds a method to a package.
sub add_method {
    my ($package, $method, %opts) = @_;

    # TODO: make sure $package is subclass of E::O.

    # determine the main callback code.
    $opts{code} ||= $package->can($method);
    if (!$code || !ref $code || ref $code ne 'CODE') {
        carp "Evented method '$method' has no code.";
        return;
    }

    # argument checking (priority 1000).
    
    # add the main callback (priority 500).
    $package->register_callback(
        $method  => $opts{code},
        name     => 'method',
        priority => 500
    );
    
    # export method caller.
    # this overwrites the method code if necessary.
    Evented::Object::export_code($package, $method, sub {
        shift->fire_event($method => @_);
    });
    
    # store method info.
    $p{$package}{methods}{$method} = \%opts;
    
    return 1;
}

1;