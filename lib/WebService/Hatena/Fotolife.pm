# $Id: Fotolife.pm 7 2005-03-28 13:13:15Z kentaro $

package WebService::Hatena::Fotolife;

use strict;
use warnings;

use FileHandle;
use Image::Info qw(image_info);

use XML::Atom::Entry;
use base qw(XML::Atom::Client);

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new
		or return $class->error($class->SUPER::errstr);

	$self->{ua}->agent("WebService::Hatena::Fotolife/$VERSION");
	return $self;
}

sub createEntry {
	my ($self, %param) = @_;

	return $self->error('title and image source are both required')
		unless $param{title} || grep {!$_} @param{qw(filename scalarref)};

	my $PostURI = 'http://f.hatena.ne.jp/atom/post';
	my $image = $self->_get_image($param{filename} || $param{scalarref})
		or return $self->error($self->errstr);
	my $entry = XML::Atom::Entry->new;
	   $entry->title($self->_encode($param{title}));
	   $entry->content(${$image->{content}});
	   $entry->content->type($image->{content_type});

	return $self->SUPER::createEntry($PostURI, $entry);
}

sub updateEntry {
	my ($self, $EditURI, %param) = @_;

	return $self->error('EditURI and title are both required')
		unless $EditURI || $param{title};

	my $entry = XML::Atom::Entry->new;
	   $entry->title($self->_encode($param{title}));

	return $self->SUPER::updateEntry($EditURI, $entry);
}

sub getFeed {
	my $self = shift;
	my $FeedURI = 'http://f.hatena.ne.jp/atom/feed';

	return $self->SUPER::getFeed($FeedURI);
}

sub _get_image {
	my ($self, $image_source) = @_;
	my $image;

	if (ref $image_source eq 'SCALAR') {
		$image = $image_source;
	} else {
		$image = do {
			local $/ = undef;
			my $fh = FileHandle->new($image_source)
				or return $self->error("can't open $image_source: $!");
			my $content = <$fh>;
			\$content;
		};
	}

	my $info  = Image::Info::image_info($image);
	return $self->error($info->{error}) if $info->{error};

	return {content => $image, content_type => $info->{file_media_type}};
}

sub _encode {
	my $string = $_[1];

	if ($] >= 5.008) {
		require Encode;
		$string = Encode::encode('utf8', $string)
			unless Encode::is_utf8($string);
	}

	return $string;
}

1;

__END__

=head1 NAME

WebService::Hatena::Fotolife - Interface to the Hatena::Fotolife AtomAPI

=head1 SYNOPSIS

  use WebService::Hatena::Fotolife;

  my $fotolife = WebService::Hatena::Fotolife->new;
     $fotolife->username($username);
     $fotolife->password($password);

  # create a new entry
  my $EditURI = $fotolife->createEntry(
      title    => $title,
      filename => $filename,
  );

  # or pass in the image source as a scalarref
  my $EditURI = $fotolife->createEntry(
      title     => $title,
      scalarref => \$image_content,
  );

  # update the entry
  $fotolife->updateEntry($EditURI, title => $title);

  # retrieve the feed
  my $feed = $fotolife->getFeed;
  my @entries = $feed->entries;
  ...

=head1 DESCRIPTION

WebService::Hatena::Fotolife provides an interface to the Hatena::Fotolife AtomAPI.

This module is a subclass of L<XML::Atom::Client>, so see also the documentation of the baseclass for more usage.

=head1 METHODS

=head2 new

=over 4

  my $fotolife = WebService::Hatena::Fotolife->new;

Creates and returns a WebService::Hatena::Fotolife object.

This method behaves the same as baseclass's one except for setting the UserAgent string "WebService::Hatena::Fotolife/$VERSION".

=back

=head2 createEntry ( I<%param> )

=over 4

  my $EditURI = $fotolife->createEntry(
      title    => $title,
      filename => $filename,
  );

or

  my $EditURI = $fotolife->createEntry(
      title     => $title,
      scalarref => $scalarref,
  );

Uploads the given image with I<$title> to Hatena::Fotolife. Pass in the image source as a filename or a scalarref to the image content.

This method overrides the baseclass's I<createEntry> method.

=back

=head2 updateEntry ( I<$EditURI>, I<%param> )

=over 4

  my $EditURI = $fotolife->updateEntry($EditURI, title => $title);

Updates the title of the entry at I<$EditURI> with the given I<$title>. Hatena::Fotolife AtomAPI currently doesn't support to update the image content directly by this method.

This method overrides the baseclass's I<updateEntry> method.

=back

=head2 getFeed

=over 4

  my $feed = $fotolife->getFeed;

Retrieves the feed. The count of the entries the I<$feed> includes depends on your configuration of Hatena::Fotolife.

This method overrides the beseclass's I<getFeed> method.

=back

=head2 use_soap ( I<[ 0 | 1 ]> )

=head2 username ( [ I<$username ]> )

=head2 password ( [ I<$password ]> )

=head2 getEntry ( I<$EditURI> )

=over 4

See the documentation of the baseclass L<XML::Atom::Client>.

=back

=head1 CAVEAT

This module is now in beta version, so the interface it provides may be changed later.

=head1 SEE ALSO

=over 4

=item * Hatena::Fotolife

http://f.hatena.ne.jp/

=item * Hatena::Fotolife API documentation

http://d.hatena.ne.jp/keyword/%A4%CF%A4%C6%A4%CA%A5%D5%A5%A9%A5%C8%A5%E9%A5%A4%A5%D5AtomAPI

=item * L<XML::Atom::Client>

=back

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentarok@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
