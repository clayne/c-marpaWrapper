#!/usr/bin/perl
# Copyright 2022 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

# This utility has two checking "modes": Perl distribution and repo.
#
# For checking a Perl distribution, use the "--dist" option, which takes
# a directory name as an argument.  This directory should be the top-level
# directory of the distribution.  The list
# of files to be checked should be all the files in the distribution.
#
# For check the repo, omit the "--dist" option.  The list of files should
# be those files tracked by git.  The "ls-files" subcommand of "git"
# produces such a list.

use 5.010001;
use strict;
use warnings;
use autodie;
# use Fatal qw(open close read);
use File::Spec;
use Text::Diff ();
use English qw( -no_match_vars );

use Getopt::Long;
my $verbose = 0;
my $dist;
my $result = Getopt::Long::GetOptions(
    'verbose=i' => \$verbose,
    # check distribution in named directory
    'dist=s'    => \$dist
);
die "usage $PROGRAM_NAME [--verbose=n] file ...\n" if not $result;
my $isDist = defined $dist;
$dist //= 'cpan';

my $copyright_line = q{Copyright 2022 Jeffrey Kegler};
( my $copyright_line_in_tex = $copyright_line )
    =~ s/ ^ Copyright \s /Copyright \\copyright\\ /xms;

my $closed_license = "$copyright_line\n" . <<'END_OF_STRING';
This document is not part of the Marpa or Marpa::R2 source.
Although it may be included with a Marpa distribution that
is under an open source license, this document is
not under that open source license.
Jeffrey Kegler retains full rights.
END_OF_STRING

my $license_body = <<'END_OF_STRING';
This file is part of Marpa::R2.  Marpa::R2 is free software: you can
redistribute it and/or modify it under the terms of the GNU Lesser
General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

Marpa::R2 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser
General Public License along with Marpa::R2.  If not, see
http://www.gnu.org/licenses/.
END_OF_STRING

my $license = "$copyright_line\n$license_body";
my $marpa_r2_license = $license;
my $libmarpa_license = $license;
$libmarpa_license  =~ s/Marpa::R2/Libmarpa/gxms;

my $mit_license_body = <<'END_OF_STRING';
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
END_OF_STRING

my $mit_license = "$copyright_line\n$mit_license_body";

# License, redone as Tex input
my $license_in_tex =
    "$copyright_line_in_tex\n" . "\\bigskip\\noindent\n" . "$license_body";
$license_in_tex =~ s/^$/\\smallskip\\noindent/gxms;

my $license_in_md = join "\n", q{<!--}, $copyright_line, $license_body;
$license_in_md .= q{-->} . "\n";

my $license_file = $license . <<'END_OF_STRING';

In the Marpa::R2 distribution, the GNU Lesser General Public License
version 3 should be in a file named "COPYING.LESSER".
END_OF_STRING

my $texi_copyright = <<'END_OF_TEXI_COPYRIGHT';
Copyright @copyright{} 2022 Jeffrey Kegler.
END_OF_TEXI_COPYRIGHT

my $fdl_license = <<'END_OF_FDL_LANGUAGE';
@quotation
Permission is granted to copy, distribute and/or modify this document
under the terms of the @acronym{GNU} Free Documentation License,
Version 1.3 or any later version published by the Free Software
Foundation.
A copy of the license is included in the section entitled
``@acronym{GNU} Free Documentation License.''
@end quotation
@end copying
END_OF_FDL_LANGUAGE

my $cc_a_nd_body = <<'END_OF_CC_A_ND_LANGUAGE';
This document is licensed under
a Creative Commons Attribution-NoDerivs 3.0 United States License.
END_OF_CC_A_ND_LANGUAGE

my $cc_a_nd_license = "$copyright_line\n$cc_a_nd_body";
my $cc_a_nd_thanks = $cc_a_nd_body;

sub hash_comment {
    my ( $text, $char ) = @_;
    $char //= q{#};
    $text =~ s/^/$char /gxms;
    $text =~ s/ [ ]+ $//gxms;
    return $text;
} ## end sub hash_comment

# Assumes $text ends in \n
sub c_comment {
    my ($text) = @_;
    $text =~ s/^/ * /gxms;
    $text =~ s/ [ ] $//gxms;
    return qq{/*\n$text */\n};
} ## end sub c_comment

# Libmarpa license is more common for C files
my $c_license          = c_comment($libmarpa_license);
my $r2_c_license          = c_comment($marpa_r2_license);

my $c_mit_license          = c_comment($mit_license);
my $mit_hash_license          = hash_comment($mit_license);
my $xs_license          = c_comment($license);
my $r2_hash_license    = hash_comment($license);
my $libmarpa_hash_license    = hash_comment($mit_license);
my $xsh_hash_license    = hash_comment($license, q{ #});
my $tex_closed_license = hash_comment( $closed_license, q{%} );
my $tex_license        = hash_comment( $license, q{%} );
my $tex_cc_a_nd_license = hash_comment( $cc_a_nd_license, q{%} );
my $indented_license   = $license;
$indented_license =~ s/^/  /gxms;
$indented_license =~ s/[ ]+$//gxms;

my $pod_section = <<'END_OF_STRING';
=head1 Copyright and License

=for Marpa::R2::Display
ignore: 1

END_OF_STRING

$pod_section .= "$indented_license\n";

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

$pod_section .= <<'END_OF_STRING';
=for Marpa::R2::Display::End

END_OF_STRING

# Next line is to fake out display checking logic
# Otherwise it will think the lines to come are part
# of a display

=cut

my @GNUdist = ("$dist/engine/read_only/");
push @GNUdist, "$dist/libmarpa_build/"
  if $isDist;
my @GNU_file = ();

for my $GNUdist (@GNUdist) {
    push @GNU_file, map { ( $GNUdist . $_, 1 ) } qw(
      aclocal.m4
      config.guess
      config.sub
      configure
      depcomp
      mdate-sh
      texinfo.tex
      ltmain.sh
      m4/libtool.m4
      m4/ltoptions.m4
      m4/ltsugar.m4
      m4/ltversion.m4
      m4/lt~obsolete.m4
      missing
      compile
      Makefile.in
    );
}

my %GNU_file = @GNU_file;

sub ignored {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    if ($verbose) {
        say {*STDERR} "Checking $filename as ignored file"
          or die "say failed: $ERRNO";
    }
    return @problems;
} ## end sub trivial

sub trivial {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as trivial file"
          or die "say failed: $ERRNO";
    }
    my $length        = 1000;
    my @problems      = ();
    my $actual_length = -s $filename;
    if ( not defined $actual_length ) {
        my $problem = qq{"Trivial" file does not exit: "$filename"\n};
        return $problem;
    }
    if ( -s $filename > $length ) {
        my $problem =
          qq{"Trivial" file is more than $length characters: "$filename"\n};
        push @problems, $problem;
    }
    return @problems;
} ## end sub trivial

sub check_GNU_copyright {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as GNU copyright file"
          or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text     = slurp_top( $filename, 1000 );
    ${$text} =~ s/^[#]//gxms;
    if ( ${$text} !~
        / \s copyright \s .* Free \s+ Software \s+ Foundation [\s,] /xmsi )
    {
        my $problem = "GNU copyright missing in $filename\n";
        if ($verbose) {
            $problem .= "$filename starts:\n" . ${$text} . "\n";
        }
        push @problems, $problem;
    } ## end if ( ${$text} !~ ...)
    return @problems;
} ## end sub check_GNU_copyright

sub check_X_copyright {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as X Consortium file"
          or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text     = slurp_top( $filename, 1000 );
    if ( ${$text} !~ / \s copyright \s .* X \s+ Consortium [\s,] /xmsi ) {
        my $problem = "X copyright missing in $filename\n";
        if ($verbose) {
            $problem .= "$filename starts:\n" . ${$text} . "\n";
        }
        push @problems, $problem;
    } ## end if ( ${$text} !~ ...)
    return @problems;
} ## end sub check_X_copyright

sub check_tag {
    my ( $tag, $length ) = @_;
    $length //= 250;
    return sub {
        my ( $filename, $verbose ) = @_;
        my @problems = ();
        my $text     = slurp_top( $filename, $length );
        if ( ( index ${$text}, $tag ) < 0 ) {
            my $problem = "tag missing in $filename\n";
            if ($verbose) {
                $problem .= "\nMissing tag:\n$tag\n";
            }
            push @problems, $problem;
        } ## end if ( ( index ${$text}, $tag ) < 0 )
        return @problems;
    }
} ## end sub check_tag

my @files_by_type = (
      'COPYING.LESSER'       => \&ignored,
);

if ( not $isDist ) {
    push @files_by_type,
      'blog/error/to_html.pl' => \&trivial,
      'CITATION.cff'          => \&trivial,
      "$dist/.inputrc"        => \&trivial,
      "$dist/TOUCH"           => \&trivial,
      'target/try.sh'         => \&trivial,
      'INSTALL_NOTES'         => \&trivial,
      'AIX.README'            => \&ignored,

      # Legalese, leave it alone
      'README' => \&ignored,

      # GNU license text, leave it alone
      "$dist/COPYING.LESSER" => \&ignored,

      "$dist/LICENSE"   => \&license_problems_in_license_file,
      'LICENSE'         => \&license_problems_in_license_file,
      "$dist/META.json" =>
      \&ignored,    # not source, and not clear how to add license at top
      "$dist/META.yml" =>
      \&ignored,    # not source, and not clear how to add license at top
      "$dist/README"                            => \&trivial,
      "$dist/INSTALL"                           => \&trivial,
      "$dist/TODO"                              => \&trivial,
      "$dist/html/script/marpa_r2_html_fmt"     =>
      gen_license_problems_in_perl_file(),
      "$dist/html/script/marpa_r2_html_score" =>
      gen_license_problems_in_perl_file(),
      "$dist/engine/README" => gen_license_problems_in_hash_file(),

      # Input and output files for tests
      'sandbox/old/ambiguities' => \&ignored,
      'sandbox/old/html.counts' => \&ignored,
      'sandbox/old/perl.counts' => \&ignored,
      'sandbox/old2/curly.in'   => \&ignored,
      'sandbox/old2/curly.out'  => \&ignored,

      "$dist/html/sandbox/loose.dtd" => \&ignored,    # Standard, leave as is

      # Input files for tests
      "$dist/html/sandbox/small.html" => \&ignored,
      "$dist/html/sandbox/local.html" => \&ignored,

      # Input and output files for tests
      'blog/dyck_hollerith/post1/dh_numbers.html' => \&ignored,
      'blog/html_cfg_dsl/plot'                    => \&ignored,
      'blog/html_config/css.html'                 => \&ignored,
      'blog/iterative/test.in'                    => \&ignored,
      'blog/iterative/test.out'                   => \&ignored,
      'blog/json/test.json'                       => \&ignored,
      'blog/search/test.in'                       => \&ignored,
      'blog/search/test.out'                      => \&ignored,
      'blog/sl/p1000.in'                          => \&ignored,
      'blog/sl/re1000.out'                        => \&ignored,
      'blog/slperl/test.in'                       => \&ignored,
      'blog/slperl/test.out'                      => \&ignored,
      'blog/whitespace/prefix.out'                => \&ignored,

      # Very short files
      'blog/op3/try.sh'     => \&trivial,
      'blog/search/test.sh' => \&trivial,
      ;
}

if ($isDist) {
    push @files_by_type,

      # autogenerated by Module::Build
      "$dist/Build" => \&ignored,

      "$dist/README" => \&trivial,
      "$dist/LICENSE"              => \&license_problems_in_license_file,
      "$dist/INSTALL"                           => \&trivial,
      "$dist/MYMETA.yml"     => \&ignored,
      "$dist/META.json"      => \&ignored,
      "$dist/META.yml"       => \&ignored,
      "$dist/MYMETA.json"    => \&ignored,
      "$dist/COPYING.LESSER" => \&ignored,
      "$dist/pperl/Marpa/R2/Perl/Version.pm"   => \&trivial,
      "$dist/pperl/Marpa/R2/Perl/Installed.pm" => \&trivial,
      "$dist/blib/arch/auto/Marpa/R2/R2.bs"    => \&ignored,
      "$dist/blib/arch/auto/Marpa/R2/R2.so"    => \&ignored,
      "$dist/blib/lib/Marpa/R2/Version.pm"     => \&trivial,
      "$dist/blib/lib/Marpa/R2/Installed.pm"   => \&trivial,
      "$dist/lib/Marpa/R2/Version.pm"          => \&trivial,
      "$dist/lib/Marpa/R2/Installed.pm"        => \&trivial,
      "$dist/lib/Marpa/R2.c"    => gen_license_problems_at_top($r2_c_license),
      "$dist/xs/marpa_slifop.h" => gen_license_problems_at_top($r2_c_license);
}

my @libmarpaDist = ("$dist/engine/read_only");
push @libmarpaDist, "$dist/libmarpa_build" if $isDist;

for my $libmarpaDist ( @libmarpaDist ) {
    push @files_by_type, (

        # Libmarpa has MIT licensing
        "$libmarpaDist/AUTHORS" => \&trivial,
        "$libmarpaDist/COPYING" => \&ignored,  # Libmarpa's special copying file
        "$libmarpaDist/COPYING.LESSER" => \&ignored,
        "$libmarpaDist/ChangeLog"      => \&trivial,
        "$libmarpaDist/GIT_LOG.txt"    => \&ignored,
        "$libmarpaDist/INSTALL"        => \&ignored,
        "$libmarpaDist/LIB_VERSION"    => \&trivial,
        "$libmarpaDist/Makefile.am"    =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/Makefile.win32" =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/NEWS"           => \&trivial,
        "$libmarpaDist/README"         => \&ignored,
        "$libmarpaDist/README.AIX"     => \&ignored,
        "$libmarpaDist/README.INSTALL" =>
          gen_license_problems_in_c_file($mit_hash_license),

        # I could port the check from Libmarpa, but it's a lot of code
        # and we will just trust that the license as copied OK
        "$libmarpaDist/api_docs/libmarpa_api.html" => \&ignored,

        "$libmarpaDist/config.h"  => \&ignored,
        "$libmarpaDist/config.h.in"  => \&ignored,
        "$libmarpaDist/configure.ac" =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/error_codes.table" =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/events.table" =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/install-sh"  => \&ignored,
        "$libmarpaDist/libmarpa.pc" =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/libmarpa.pc.in" =>
          gen_license_problems_in_c_file($mit_hash_license),

        # Short and auto-generated
        "$libmarpaDist/libmarpa_version.sh" => \&trivial,

        "$libmarpaDist/marpa.c" =>
          gen_license_problems_in_c_file($c_mit_license),
        "$libmarpaDist/marpa.h" =>
          gen_license_problems_in_c_file($c_mit_license),
        "$libmarpaDist/marpa_ami.c" =>
          gen_license_problems_in_c_file($c_mit_license),
        "$libmarpaDist/marpa_ami.h" =>
          gen_license_problems_in_c_file($c_mit_license),

        # Leave Pfaff's licensing as is
        "$libmarpaDist/marpa_avl.c"  => \&ignored,
        "$libmarpaDist/marpa_avl.h"  => \&ignored,
        "$libmarpaDist/marpa_tavl.c" => \&ignored,
        "$libmarpaDist/marpa_tavl.h" => \&ignored,

        "$libmarpaDist/marpa_codes.c" =>
          gen_license_problems_in_c_file($c_mit_license),
        "$libmarpaDist/marpa_codes.h" =>
          gen_license_problems_in_c_file($c_mit_license),

        # Leave obstack licensing as is
        "$libmarpaDist/marpa_obs.c" => \&ignored,
        "$libmarpaDist/marpa_obs.h" => \&ignored,

        "$libmarpaDist/steps.table" =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/version.m4"           => \&trivial,
        "$libmarpaDist/win32/do_config_h.pl" =>
          gen_license_problems_in_c_file($mit_hash_license),
        "$libmarpaDist/win32/marpa.def" => \&ignored,

      "$dist/html/t/fmt_t_data/expected1.html"       => \&ignored,
      "$dist/html/t/fmt_t_data/expected2.html"       => \&ignored,
      "$dist/html/t/fmt_t_data/expected3.html"       => \&ignored,
      "$dist/html/t/fmt_t_data/input1.html"          => \&trivial,
      "$dist/html/t/fmt_t_data/input2.html"          => \&trivial,
      "$dist/html/t/fmt_t_data/input3.html"          => \&trivial,
      "$dist/html/t/fmt_t_data/score_expected1.html" => \&trivial,
      "$dist/html/t/fmt_t_data/score_expected2.html" => \&trivial,
      "$dist/html/t/no_tang.html"                    => \&ignored,
      "$dist/html/t/test.html"                       => \&ignored,

      "$dist/author.t/accept_tidy"              => \&trivial,
      "$dist/author.t/critic1"                  => \&trivial,
      "$dist/author.t/perltidyrc"               => \&trivial,
      "$dist/author.t/spelling_exceptions.list" => \&trivial,
      "$dist/author.t/tidy1"                    => \&trivial,

      "$dist/etc/my_suppressions"                    => \&trivial,
      "$dist/etc/pod_errors.pl"                 => \&trivial,
      "$dist/etc/pod_dump.pl"                   => \&trivial,
      "$dist/etc/dovg.sh"                       => \&trivial,
      "$dist/etc/compile_for_debug.sh"          => \&trivial,
      "$dist/etc/libmarpa_test.sh"              => \&trivial,
      "$dist/etc/reserved_check.sh"             => \&trivial,

      "$dist/xs/ppport.h" => \&ignored,  # copied from CPAN, just leave it alone
    );
}

if ($isDist) {
    my $libmarpaDist = "$dist/libmarpa_build";
    push @files_by_type,
      "$libmarpaDist/.libs/libmarpa.lai" => \&ignored,
      "$libmarpaDist/libtool"            => \&ignored,
      "$libmarpaDist/config.status"      => \&ignored,
      "$libmarpaDist/Makefile"           => \&ignored,
      "$libmarpaDist/stamp-h1"           => \&ignored,
      "$libmarpaDist/config.log"         => \&ignored,
      "$libmarpaDist/SWITCHED_TO"        => \&trivial;
}

my %files_by_type = @files_by_type;

sub file_type {
    my ($filename) = @_;
    my $closure = $files_by_type{$filename};
    return $closure if defined $closure;
    my ( $volume, $dirpart, $filepart ) = File::Spec->splitpath($filename);
    my @dirs = grep { length } File::Spec->splitdir($dirpart);

    # Ignore autogenerated troff of POD files
    return \&ignored
      if $isDist
      and $filename =~ m/$dist[\/]blib[\/]libdoc[\/]Marpa::R2[^\/]*[.]3$/;

    # Ignore autogenerated Module::Build files
    return \&ignored
      if $isDist
      and $filename =~ m/$dist[\/]_build[\/][^\/]*$/;

    return \&ignored if $filepart =~ /[.]tar\z/xms;

    # PDF files are generated -- licensing is in source
    return \&ignored if $filepart =~ /[.] (pdf) \z /xms;

    # Ignore libraries, object files, etc
    return \&ignored if $filepart =~ /[.] (Plo|lo|la|o|a) \z /xms;

    # info files are generated -- licensing is in source
    return \&ignored if $filepart =~ /[.]info\z/xms;
    return \&trivial if $filepart eq '.gitignore';
    return \&trivial if $filepart eq '.gitattributes';
    return \&trivial if $filepart eq '.gdbinit';
    return \&check_GNU_copyright
      if $GNU_file{$filename};
    return gen_license_problems_in_perl_file()
      if $filepart =~ /[.] (t|pl|pm|PL) \z /xms;
    return gen_license_problems_in_perl_file()
      if $filepart eq 'typemap';
    return \&license_problems_in_fdl_file
      if $filepart eq 'internal.texi';
    return \&license_problems_in_fdl_file
      if $filepart eq 'api.texi';
    return \&license_problems_in_pod_file if $filepart =~ /[.]pod \z/xms;
    return gen_license_problems_at_top($license_in_md)
      if $filepart =~ /[.] (md) \z /xms;
    return gen_license_problems_in_c_file($xs_license)
      if $filepart =~ /[.] (xs) \z /xms;
    return gen_license_problems_in_c_file()
      if $filepart =~ /[.] (c|h) \z /xms;
    return \&license_problems_in_xsh_file
      if $filepart =~ /[.] (xsh) \z /xms;
    return \&license_problems_in_sh_file
      if $filepart =~ /[.] (sh) \z /xms;
    return gen_license_problems_in_c_file()
      if $filepart =~ /[.] (c|h) [.] in \z /xms;
    return \&license_problems_in_tex_file
      if $filepart =~ /[.] (w) \z /xms;
    return gen_license_problems_in_hash_file();

} ## end sub file_type

sub file_license_problems {
    my ( $filename, $verbose ) = @_;
    $verbose //= 0;
    my @problems = ();
    my $closure  = file_type($filename);
    if ( not defined $closure ) {
        return nyi( $filename, $verbose );
    }
    push @problems, $closure->( $filename, $verbose );
    return @problems;

} ## end sub file_license_problems

sub license_problems {
    my ( $files, $verbose ) = @_;
    return map { file_license_problems( $_, $verbose ) } @{$files};
} ## end sub license_problems

sub slurp {
    my ($filename) = @_;
    local $RS = undef;
    open my $fh, q{<}, $filename;
    my $text = <$fh>;
    close $fh;
    return \$text;
} ## end sub slurp

sub slurp_top {
    my ( $filename, $length ) = @_;
    $length //= 1000 + ( length $license );
    local $RS = undef;
    open my $fh, q{<}, $filename;
    my $text;
    read $fh, $text, $length;
    close $fh;
    return \$text;
} ## end sub slurp_top

sub files_equal {
    my ( $filename1, $filename2 ) = @_;
    return ${ slurp($filename1) } eq ${ slurp($filename2) };
}

sub tops_equal {
    my ( $filename1, $filename2, $length ) = @_;
    return ${ slurp_top( $filename1, $length ) } eq
      ${ slurp_top( $filename2, $length ) };
}

sub license_problems_in_license_file {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text     = ${ slurp($filename) };
    if ( $text ne $license_file ) {
        my $problem = "LICENSE file is wrong\n";
        if ($verbose) {
            $problem .=
                "=== Differences ===\n"
              . Text::Diff::diff( \$text, \$license_file )
              . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( $text ne $license_file )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== $filename should be as follows:\n"
          . $license_file
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_license_file

sub gen_license_problems_in_hash_file {
    my ( $license, $maxPrefix ) = @_;
    $license //= $r2_hash_license;
    return gen_license_problems_at_top( $license, $maxPrefix );
} ## end sub gen_license_problems_in_hash_file

sub license_problems_in_xsh_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as hash style file"
          or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text     = slurp_top( $filename, length $xsh_hash_license );
    if ( $xsh_hash_license ne ${$text} ) {
        my $problem = "No license language in $filename (hash style)\n";
        if ($verbose) {
            $problem .=
                "=== Differences ===\n"
              . Text::Diff::diff( $text, \$xsh_hash_license )
              . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( $xsh_hash_license ne ${$text} )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== license for $filename should be as follows:\n"
          . $xsh_hash_license
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_xsh_file

sub license_problems_in_sh_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as sh hash style file"
          or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $ref_text = slurp_top( $filename, 256 + length $r2_hash_license );
    my $text     = ${$ref_text};
    $text =~ s/ \A [#][!] [^\n]* \n//xms;
    $text = substr $text, 0, length $r2_hash_license;
    if ( $r2_hash_license ne $text ) {
        my $problem = "No license language in $filename (sh hash style)\n";
        if ($verbose) {
            $problem .=
                "=== Differences ===\n"
              . Text::Diff::diff( \$text, \$r2_hash_license )
              . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    }
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== license for $filename should be as follows:\n"
          . $r2_hash_license
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
}

sub gen_license_problems_in_perl_file {
    my ($license) = @_;
    my $perl_license = $license // $r2_hash_license;
    return sub {
        my ( $filename, $verbose ) = @_;
        if ($verbose) {
            say {*STDERR} "Checking $filename as perl file"
              or die "say failed: $ERRNO";
        }
        $verbose //= 0;
        my @problems = ();
        my $text     = slurp_top( $filename, 132 + length $perl_license );

        # Delete hash bang line, if present
        ${$text} =~ s/\A [#][!] [^\n] \n//xms;
        if ( 0 > index ${$text}, $perl_license ) {
            my $problem = "No license language in $filename (perl style)\n";
            if ($verbose) {
                $problem .=
                    "=== Differences ===\n"
                  . Text::Diff::diff( $text, \$perl_license )
                  . ( q{=} x 30 );
            } ## end if ($verbose)
            push @problems, $problem;
        } ## end if ( 0 > index ${$text}, $perl_license )
        if ( scalar @problems and $verbose >= 2 ) {
            my $problem =
                "=== license for $filename should be as follows:\n"
              . $perl_license
              . ( q{=} x 30 );
            push @problems, $problem;
        } ## end if ( scalar @problems and $verbose >= 2 )
        return @problems;
    };
} ## end sub gen_license_problems_in_perl_file

sub gen_license_problems_in_c_file {
    my ($license) = @_;
    $license //= $c_license;
    return sub {
        my ( $filename, $verbose ) = @_;
        if ($verbose) {
            say {*STDERR} "Checking $filename as C file"
              or die "say failed: $ERRNO";
        }
        my @problems = ();
        my $text     = slurp_top( $filename, 500 + length $license );
        ${$text} =~
          s{ \A [/][*] \s+ DO \s+ NOT \s+ EDIT \s+ DIRECTLY [^\n]* \n }{}xms;
        if ( ( index ${$text}, $license ) < 0 ) {
            my $problem = "No license language in $filename (C style)\n";
            if ($verbose) {
                $problem .=
                    "=== Differences ===\n"
                  . Text::Diff::diff( $text, \$license )
                  . ( q{=} x 30 );
            } ## end if ($verbose)
            push @problems, $problem;
        } ## end if ( ( index ${$text}, $license ) < 0 )
        if ( scalar @problems and $verbose >= 2 ) {
            my $problem =
                "=== license for $filename should be as follows:\n"
              . $license
              . ( q{=} x 30 );
            push @problems, $problem;
        } ## end if ( scalar @problems and $verbose >= 2 )
        return @problems;
    };
} ## end sub gen_license_problems_in_c_line

sub license_problems_in_tex_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as TeX file"
          or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text     = slurp_top( $filename, 200 + length $tex_license );
    ${$text} =~ s{ \A [%] \s+ DO \s+ NOT \s+ EDIT \s+ DIRECTLY [^\n]* \n }{}xms;
    if ( ( index ${$text}, $tex_license ) < 0 ) {
        my $problem = "No license language in $filename (TeX style)\n";
        if ($verbose) {
            $problem .=
                "=== Differences ===\n"
              . Text::Diff::diff( $text, \$tex_license )
              . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== license for $filename should be as follows:\n"
          . $tex_license
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_tex_file

# This was the license for the lyx documents
# For the Latex versions, I switched to CC-A_ND
sub tex_closed {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text     = slurp_top( $filename, 400 + length $tex_closed_license );

    if ( ( index ${$text}, $tex_closed_license ) < 0 ) {
        my $problem = "No license language in $filename (TeX style)\n";
        if ($verbose) {
            $problem .=
                "=== Differences ===\n"
              . Text::Diff::diff( $text, \$tex_closed_license )
              . ( q{=} x 30 );
        } ## end if ($verbose)
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_closed_license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== license for $filename should be as follows:\n"
          . $tex_closed_license
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub tex_closed

# Note!!!  This license is not Debian-compatible!!!
sub tex_cc_a_nd {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text     = slurp($filename);

    # say "=== Looking for\n", $tex_cc_a_nd_license, "===";
    # say "=== Looking in\n", ${$text}, "===";
    # say STDERR index ${$text}, $tex_cc_a_nd_license ;

    if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 ) {
        my $problem = "No CC-A-ND language in $filename (TeX style)\n";
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 )
    if ( ( index ${$text}, $cc_a_nd_thanks ) < 0 ) {
        my $problem = "No CC-A-ND LaTeX thanks in $filename\n";
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 )
    if ( ( index ${$text}, $copyright_line_in_tex ) < 0 ) {
        my $problem = "No copyright line in $filename\n";
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $tex_cc_a_nd_license ) != 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== license for $filename should be as follows:\n"
          . $tex_closed_license
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub tex_closed

sub cc_a_nd {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    my $text     = slurp($filename);
    if ( ( index ${$text}, $cc_a_nd_body ) < 0 ) {
        my $problem = "No CC-A-ND language in $filename (TeX style)\n";
        push @problems, $problem;
    }
    if ( ( index ${$text}, $copyright_line ) < 0 ) {
        my $problem = "No copyright line in $filename\n";
        push @problems, $problem;
    }
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== license for $filename should be as follows:\n"
          . $cc_a_nd_body
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub cc_a_nd

sub copyright_page {
    my ( $filename, $verbose ) = @_;

    my @problems = ();
    my $text     = ${ slurp($filename) };
    if ( $text =~ m/ ^ Copyright \s [^J]* \s Jeffrey \s Kegler $ /xmsp ) {
        ## no critic (Variables::ProhibitPunctuationVars);
        my $pos = length ${^PREMATCH};
        $text = substr $text, $pos;
    }
    else {
        push @problems,
"No copyright and license language in copyright page file: $filename\n";
    }
    if ( not scalar @problems and ( index $text, $license_in_tex ) < 0 ) {
        my $problem = "No copyright/license in $filename\n";
        if ($verbose) {
            $problem .= "Missing copyright/license:\n"
              . Text::Diff::diff( \$text, \$license_in_tex );
        }
        push @problems, $problem;
    } ## end if ( not scalar @problems and ( index $text, $license_in_tex...))
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== copyright/license in $filename should be as follows:\n"
          . $license_in_tex
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub copyright_page

sub license_problems_in_pod_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as POD file"
          or die "say failed: $ERRNO";
    }

    # Pod files are Perl files, and should also have the
    # license statement at the start of the file
    my $closure  = gen_license_problems_in_perl_file();
    my @problems = $closure->( $filename, $verbose );

    my $text = ${ slurp($filename) };
    if ( $text =~ m/ ^ [=]head1 \s+ Copyright \s+ and \s+ License /xmsp ) {
        ## no critic (Variables::ProhibitPunctuationVars);
        my $pos = length ${^PREMATCH};
        $text = substr $text, $pos;
    }
    else {
        push @problems,
          qq{No "Copyright and License" header in pod file $filename\n};
    }
    if ( not scalar @problems and ( index $text, $pod_section ) < 0 ) {
        my $problem = "No LICENSE pod section in $filename\n";
        if ($verbose) {
            $problem .= "Missing pod section:\n"
              . Text::Diff::diff( \$text, \$pod_section );
        }
        push @problems, $problem;
    } ## end if ( not scalar @problems and ( index $text, $pod_section...))
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== licensing pod section for $filename should be as follows:\n"
          . $pod_section
          . ( q{=} x 30 ) . "\n";
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_pod_file

sub gen_license_problems_at_top {
    my ( $license, $maxPrefix ) = @_;
    $maxPrefix //= length $license;
    return sub {
        my ( $filename, $verbose ) = @_;
        my @problems = ();
        my $text     = slurp_top( $filename, ( length $license ) + $maxPrefix );
        if ( ( index ${$text}, $license ) < 0 ) {
            my $problem = "Full language missing in file $filename\n";
            if ($verbose) {
                $problem .= "\nMissing license language:\n"
                  . Text::Diff::diff( $text, \$license );
            }
            push @problems, $problem;
        } ## end if ( ( index ${$text}, $license ) < 0 )
        if ( scalar @problems and $verbose >= 2 ) {
            my $problem =
                "=== licensing for $filename should be as follows:\n"
              . $license
              . ( q{=} x 30 );
            push @problems, $problem;
        } ## end if ( scalar @problems and $verbose >= 2 )
        return @problems;
    }
}

sub license_problems_in_fdl_file {
    my ( $filename, $verbose ) = @_;
    if ($verbose) {
        say {*STDERR} "Checking $filename as FDL file"
          or die "say failed: $ERRNO";
    }
    my @problems = ();
    my $text     = slurp_top($filename);
    if ( ( index ${$text}, $texi_copyright ) < 0 ) {
        my $problem = "Copyright missing in texinfo file $filename\n";
        if ($verbose) {
            $problem .= "\nMissing FDL license language:\n"
              . Text::Diff::diff( $text, \$fdl_license );
        }
        push @problems, $problem;
    }
    if ( ( index ${$text}, $fdl_license ) < 0 ) {
        my $problem = "FDL language missing in text file $filename\n";
        if ($verbose) {
            $problem .= "\nMissing FDL license language:\n"
              . Text::Diff::diff( $text, \$fdl_license );
        }
        push @problems, $problem;
    } ## end if ( ( index ${$text}, $fdl_license ) < 0 )
    if ( scalar @problems and $verbose >= 2 ) {
        my $problem =
            "=== FDL licensing section for $filename should be as follows:\n"
          . $pod_section
          . ( q{=} x 30 );
        push @problems, $problem;
    } ## end if ( scalar @problems and $verbose >= 2 )
    return @problems;
} ## end sub license_problems_in_fdl_file

sub nyi {
    my ( $filename, $verbose ) = @_;
    my @problems = ();
    push @problems, "License checking not yet implemented in $filename\n";
    return @problems;
}

my $file_count = @ARGV;
my @license_problems =
  map { file_license_problems( $_, $verbose ) } @ARGV;

print join q{}, @license_problems;

my $problem_count = scalar @license_problems;

$problem_count and say +( q{=} x 50 );
say
"Found $problem_count license language problems after examining $file_count files";

exit $problem_count;

# vim: expandtab shiftwidth=4:
