#!/usr/bin/env perl

=pod
    Description:
        This Perl script is a glorified bash script for reducing
        repetitive actions when grading several student's c++ 
        assignments.

    Issues:
        1. It requires a consistent input format.
        2. It relies on heavily on system 
        3. It's slow and inefficient
           3.1 globbing frequently over storing once into an array
=cut

use strict;
use warnings;

sub job {
    my $path = shift;
    # if a Makefile exists, try to compile it
    # redirect output to build.txt
    my ($file) = grep($_ eq "Makefile", glob '*');
    if ($file) {
        system("make > build.txt 2>&1");
    }
    else {
        # if a cpp file exists, lets try to compile.. them
        # redirect output to build.txt
        $file = grep(/\.cpp$/, glob '*');
        if ($file) {
            system("g++ -std=c++11 *.cpp > build.txt 2>&1");
        }
    }
    system("cp $path/data.txt data.txt");
}

sub search {
    my $root = shift;
    my @subdirs = grep(-d, glob '*');
    if (@subdirs) {
        foreach (@subdirs) {
            chdir $_;
            search($root . "/.."); # append breadcrumbs as we recurse deeper
            chdir "..";
        }
    }
    job($root);
}

# store all directories from current directory
# todo: replace as many globs with readdir as possible
# todo: change syntax to reduce (), but I like ()
my @dirs = grep(-d, glob '*');
foreach (@dirs) {
    opendir DIR, $_ or die "Unable to open directory $_: $!";
    chdir $_ or die "Unable to change directory to $_: $!";

    # if an archive exists, let's try to extract it
    my ($archive) = grep(/\.(zip|tar|tar\.gz|7z)$/, glob '*');
    if ($archive) { 
        my ($ext) = $archive =~ /((\.[^.\s]+)+)$/; # parse file extension
        if ($ext eq ".zip") {
            if (system("unzip $archive > /dev/null 2>&1")) {
                die "Unable to unzip $_/$archive!";
            }
        }
        elsif ($ext eq ".tar") {
            if (system("tar -xf $archive")) {
                die "Unable to tar -xf $_/$archive!";
            }
        }
        elsif ($ext eq ".tar.gz") {
            if (system("tar -xzf $archive")) {
                die "Unable to tar -xzf $_/$archive!";
            }
        }
        elsif ($ext eq ".7z") {
            if (system("7z e $archive > /dev/null 2>&1")) {
                die "Unable to 7z e $_/$archive!";
            }
        }
    }

    search("..");
    
    chdir ".." or die "Unable to return to parent directory: $!";
    closedir DIR or die "Unable to close directory $_: $!";
}

