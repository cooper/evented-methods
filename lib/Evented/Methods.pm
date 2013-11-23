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

our $VERSION = 0.3;

# Evented::Methods import subroutine.
sub import {
    my ($class, @opts) = @_;
    my $package = caller;
    
    # store Evented::Properties options.
    my $store = Evented::Object::_package_store($package)->{EventedMethods} ||= {};
    $store->{desired} = \@opts;
    
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

    # argument checking (priority 1000).
    
    # add the main callback (priority 500).
    $package->register_callback(
        $method  => sub {
        
            # determine the main callback code.
            my $code = $opts{code} ||= $package->can("e_$method");
            if (!$code || !ref $code || ref $code ne 'CODE') {
                carp "Evented method '$method' has no code.";
                return;
            }
        
            $_[0]->{return} = $code->(@_);
            
        },
        name     => 'method',
        priority => 500
    );
    
    # export method caller.
    # this overwrites the method code if necessary.
    Evented::Object::export_code($package, $method, sub {
        my $fire = shift->fire_event($method => @_);
        return $fire->{return};
    });
    
    # store method info.
    my $store = Evented::Object::_package_store($package)->{EventedMethods} ||= {};
    $store->{methods}{$method} = \%opts;
    
    return 1;
}

1;