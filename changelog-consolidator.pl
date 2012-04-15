#! /usr/bin/perl -w

#
# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#


use strict;
use warnings;
use diagnostics;
use CGI;
use Getopt::Long;

# Currently available output formats:
#  short - short log (default)
#  long - full logs
#  html - short log with cgit links
#  stat - diff stats
#
# Input is provided as a list of modules with a from and to version, or
# "-" if no version is included, such as:
#
#                                MODULE   7.5       7.6
#                                ------  -----     ------
#                           applewmproto 1.4.1     1.4.1
#                               bdftopcf 1.0.2     1.0.3
# [...]


my $output_type = 'short';

my $result = GetOptions ("type=s" => \$output_type);

my $usage = "Usage: [--type=short|long|html|stat] <filename>\n";

if ((!$result) ||
    (($output_type ne 'short') && ($output_type ne 'long') &&
     ($output_type ne 'html')&& ($output_type ne 'stat') )) {
  print STDERR $usage;
  exit 1;
}

my @modtypes=qw(app data doc driver font lib proto util xcb .);

my %modmap = (
	      'libXres' => 'libXRes',
	      'libpthread-stubs' => 'pthread-stubs',
	      'util-macros' => 'macros',
	      'xbitmaps' => 'bitmaps',
	      'xcb-proto' => 'proto',
	      'xcursor-themes' => 'cursors',
	      'xorg-server' => 'xserver',
	      'xproto' => 'x11proto',
	      'xtrans' => 'libxtrans',
	     );

my %module_info = ();

while ($_= <>) {
  chomp($_);
  if ($_ =~ m/(\S+)\s+([\-\.\d]+)\s+([\.\d\-\*]+)/) {
    my ($module, $old, $new) = ($1, $2, $3);
    my $modtype = "?";
    my $moddir = $module;

    next if $new eq '-';

    if (exists($modmap{$module})) {
      $moddir = $modmap{$module};
    }

    if ($module =~ m/font-(.*)/) {
      $moddir = $1;
      $modtype = 'font';
    } else {
      foreach my $m (@modtypes) {
	if (-d "$m/$moddir") {
	  $modtype = $m;
	  last;
	}
      }
    }

    if (($modtype ne '?') && (($old ne $new) || ($output_type eq 'html'))) {
      if ($output_type ne 'html') {
	print "======= $modtype/$module ($old..$new)\n\n";
      }
      my $oldtag = find_tag($modtype, $moddir, $module, $old);
      my $newtag = find_tag($modtype, $moddir, $module, $new);
#      print "$modtype/$module: $oldtag -> $newtag\n";
#      system('git', "--git-dir=$modtype/$moddir/.git", 'log',
#	     '--pretty=short', "$oldtag..$newtag");

      # special cases for X11R7.7
      if ($module eq 'xkeyboard-config') {
	  $oldtag = 'xkeyboard-config-2.0';
      }

      my $tagrange = ($oldtag ne '') ? "$oldtag..$newtag" : "$newtag";

      my $output_flags = ($output_type eq 'long') ? '' : '--pretty=short';

      my $git_subcmd = ($output_type eq 'stat') ? 'diff --shortstat' : 'log';

      my $git_log_cmd = "git --git-dir=$modtype/$moddir/.git" .
	  " $git_subcmd $output_flags $tagrange";

      if ($output_type eq 'short') {
	system("$git_log_cmd | git shortlog");
      } elsif (($output_type eq 'long') || ($output_type eq 'stat')) {
	system("$git_log_cmd");
      } else {
	my %changes = ();
	open my $gsl, '-|', $git_log_cmd or die;
	while (my $ll = <$gsl>) {
	  chomp($ll);
	  my $commit = {};
	  my $author;

	  if ($ll =~ m{^commit (\w+)$}) {
	    $commit->{id} = $1;

	    while ($ll = <$gsl>) {
	      chomp($ll);
	      last if $ll =~ m{^\s*$};
	      if ($ll =~ m{^Author:\s*(.*)\s+\<.*\>}) {
		$author = $1;
	      } elsif ($ll !~ m{^Merge:}) {
		die "Author match failed: $modtype/$module/$commit->{id}\n$ll\n";
	      }
	    }

	    my $desc = "";
	    while ($ll = <$gsl>) {
	      last if $ll =~ m{^\s*$};
	      $ll =~ s{^    }{};
	      $desc .= $ll;
	    }
	    chomp($desc);
	    $commit->{desc} = $desc;

	    if (!exists $changes{$author}) {
	      $changes{$author} = [ ];
	    }
	    unshift @{$changes{$author}}, $commit;
	  }
	}
	close $gsl;
	my $newtagdate = `git --git-dir=$modtype/$moddir/.git log -1 --tags --simplify-by-decoration --pretty="format:%ad" --date=short $newtag`;
	$module_info{"$modtype/$module"} =
	  {
	   changes => \%changes,
	   oldtag => $oldtag,
	   newtag => $newtag,
	   newtagdate => $newtagdate,
	   modtype => $modtype,
	   moddir => $moddir,
	   module => $module,
	   oldvers => $old,
	   newvers => $new
	  };
      }
    }
  } else {
#    print $_, "\n";
  }
}

if ($output_type eq 'html') {
  my $q = new CGI;

  my $title = 'Consolidated ChangeLog for X11R7.7';
  print $q->start_html(-title => $title,
		       -style=>{-src =>'http://cgit.freedesktop.org/cgit.css',
				-code => '.modules { float: left; }' .
				    '.modules > td { padding-left: 3px; }'
			       },
		       -encoding => 'utf-8',
		       -head => [
			  $q->Link({-rel => 'home',
				    -href => 'http://www.x.org/'}),
			  $q->Link({-rel => 'SHORTCUT ICON',
				    -href => 'favicon.ico'}),
			  $q->Link({-rel => 'up',
				    -href => 'index.html'}),
		       ],
		       -itemscope => undef,
		       -itemtype => 'http://schema.org/WebPage'
      ), "\n";
  print
      $q->div({ -style => 'text-align: center;',
		-itemprop => 'publisher', -content => 'X.Org Foundation' },
	      $q->a({ -href => 'http://www.x.org/', -rel => 'home'},
		    $q->img({ -src => 'logo.png', -border => '0',
			      -alt => 'X.Org Foundation' }))), "\n",
      $q->h1($title), "\n";

  print $q->start_table({ -class => 'modules', -cols => '4' }), "\n",
    $q->Tr($q->th({-colspan=>"2"}, 'Module'),
	   $q->th([' X11R7.6 ', ' X11R7.7 '])), "\n";

  my $midpoint = scalar(keys %module_info) / 2;

  foreach my $m (sort keys %module_info) {
    my $modname = $module_info{$m}->{module};
    my $moddisplay = $m;
    print $q->Tr($q->td( [
			  $module_info{$m}->{modtype},
			  $q->a({href=>"#$modname"},
				$module_info{$m}->{moddir}),
			  $module_info{$m}->{oldvers},
			  $module_info{$m}->{newvers}
			 ])), "\n";
    if (--$midpoint == 0) {
      print $q->end_table();
      print $q->start_table({ -class => 'modules', -cols => '4' }).
	$q->Tr($q->th({-colspan=>"2"}, 'Module'),
	       $q->th([' X11R7.6 ', ' X11R7.7 '])), "\n";
    }
  }
  print $q->end_table();
  print $q->br({-clear => "all"}), "\n";

  foreach my $m (sort keys %module_info) {
    my $modname = $module_info{$m}->{module};
    my $modtype = $module_info{$m}->{modtype};
    my $moddir = $module_info{$m}->{moddir};
    my $modvers = $module_info{$m}->{newvers};
    my $modtar = "$modname-$modvers.tar.bz2";
    my $moddisplay = $m;
    $moddisplay =~ s{^\./}{};
    print
	$q->start_div({-class => "content", -itemscope => undef,
		       -itemtype=>'http://schema.org/SoftwareApplication'}),
	$q->h2($q->span({-itemprop => "name"},
	       cgit_link($q, $modtype, $moddir, 'top', $modname, $moddisplay)),
	       $q->span({ -itemprop => 'version' }, $modvers)),
	"\n";
    print
	$q->a({ -href => "src/everything/$modtar",
		-itemprop => 'downloadURL' }, $modtar),
	' &mdash; ', $q->span({ -itemprop => 'datePublished' },
			      $module_info{$m}->{newtagdate}), "\n";
    print $q->h3('Commits from',
		 ($module_info{$m}->{oldtag} eq '') ?
		 'the beginning' :
		 cgit_link($q, $modtype, $moddir, 'tag',
			   $module_info{$m}->{oldtag},
			   $module_info{$m}->{oldtag}
			  ),
		 'to',
		 cgit_link($q, $modtype, $moddir, 'tag',
			   $module_info{$m}->{newtag},
			   $module_info{$m}->{newtag}
			  )
		), "\n";

    print $q->start_ul({ -class => 'authors', -itemprop => 'versionChanges' });
    my $changes = $module_info{$m}->{changes};
    foreach my $a (sort keys %{$changes}) {
      my @au_changes = @{$changes->{$a}};
      my $count = scalar @au_changes;
      print $q->li("$a ($count):",
		   $q->ul({ -class => 'commits' },
			  $q->li([map {
		     cgit_link($q, $modtype, $moddir, 'commit',
			       $_->{id}, $_->{desc}) } @au_changes]))
		  ), "\n";
    }
    print $q->end_ul();
    print $q->end_div(), "\n";
  }
  print $q->end_html(), "\n";
}

sub cgit_link {
  my ($q, $modtype, $moddir, $type, $id, $body) = @_;
  # http://cgit.freedesktop.org/xorg/xserver/tag/?id=xorg-server-1.7.1
  # http://cgit.freedesktop.org/xorg/xserver/commit/?id=9a2f6135bfb0f12ec28f304c97917d2f7c64db05
  if ($modtype ne 'xcb') {
    if ($modtype eq '.') {
      $modtype = "xorg";
      # special cases for X11R7.6
#      if ($id eq '9edb9e9b4dde6f73dc5241d078425a7a70699ec9') {
#	$type = 'commit';
#      }
    } else {
      $modtype = "xorg/$modtype";
    }
  }
  my $modpath = "$modtype/$moddir";
  if ($moddir eq "xkeyboard-config") {
      $modpath = "xkeyboard-config";
  }

  my %link_attrs = (-href => "http://cgit.freedesktop.org/$modpath/");
  if ($type eq 'top') {
    $link_attrs{-name} = $id;
  } else {
    $link_attrs{-href} .= "$type/?id=$id";
  }
  my $link = $q->a(\%link_attrs, $q->escapeHTML($body));
  return $link;
}

sub find_tag {
  my ($modtype, $moddir, $module, $vers) = @_;

  if ($vers eq '*') {
    return 'HEAD';
  }

  if ($vers eq '-') {
    return '';
  }

  my $oldvers = $vers;
  $oldvers =~ s/\./_/g;

  if (-f "$modtype/$moddir/.git/refs/tags/$module-$vers") {
    return "$module-$vers";
  } elsif (-f "$modtype/$moddir/.git/refs/tags/$vers") {
    return "$vers";
  } else {
    if (-f "$modtype/$moddir/.git/refs/tags/$module-$oldvers") {
      return "$module-$oldvers";
    }
  }

  $vers =~ s/\./\\./g;

  open(my $tag_fh, '-|', "git --git-dir=$modtype/$moddir/.git tag -l")
    or die "Failed to run git --git-dir=$modtype/$moddir/.git tag -l";

  my $found;
  while (my $t = <$tag_fh>) {
    chomp($t);
    if (($t =~ m/$vers$/) || ($t =~ m/$oldvers$/)) {
      $found = $t;
    }
  }
  close($tag_fh);
  if ($found) {
      return $found;
  }

  if (-f "$modtype/$moddir/.git/refs/tags/XORG-7_1") {
    return 'XORG-7_1';
  }

  return '';
}

#    if [[ -d "$TOP/$d/.git" && ! -f "$TOP/$d/NO-PULL" ]] ; then
#	cd $TOP/$d
#	LAST_TAG="$(git describe --abbrev=0)"
#	if [[ -z "${LAST_TAG}" ]] ; then
#	    LAST_TAG="$(git describe --abbrev=0 --all HEAD^)"
#	fi
#	git log "${LAST_TAG}"..

