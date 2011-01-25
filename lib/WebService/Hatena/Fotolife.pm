package WebService::Hatena::Fotolife;
use 5.008001;
use base qw(XML::Atom::Client);

use strict;
use warnings;
use FileHandle;
use Encode qw(encode_utf8 is_utf8);
use Image::Info qw(image_info);

use WebService::Hatena::Fotolife::Entry;

our $VERSION = '0.04';
our $PostURI = 'http://f.hatena.ne.jp/atom/post';
our $FeedURI = 'http://f.hatena.ne.jp/atom/feed';

use constant GEORSS => q<http://www.georss.org/georss>;

sub new {
    my $class   = shift;
    my %params  = @_;
    my $headers = delete $params{headers} || [];
    my $self    = $class->SUPER::new(%params)
        or return $class->error($class->SUPER::errstr);

    $self->{headers} = $headers;
    $self->{ua}->agent(__PACKAGE__."/$VERSION");
    $self;
}

sub createEntry {
    my ($self, %param) = @_;

    return $self->error('title and image source are both required')
        unless $param{title} || grep {!$_} @param{qw(filename scalarref)};

    my $image = $self->_get_image($param{filename} || $param{scalarref})
        or return $self->error($self->errstr);

    my $entry = WebService::Hatena::Fotolife::Entry->new;
       $entry->title($param{title});
       $entry->content(${$image->{content}});
       $entry->content->type($image->{content_type});
       $entry->generator($param{generator}) if $param{generator};

    if ($param{folder}) {
        my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
        $entry->set($dc, 'subject', $param{folder});
    }

    if ($param{lat} and $param{lon}) {
        my $georss = XML::Atom::Namespace->new(georss => GEORSS);
        $entry->set($georss, 'point', $param{lat} . ' ' . $param{lon});
    }

    $self->SUPER::createEntry($PostURI, $entry);
}

sub updateEntry {
    my ($self, $EditURI, %param) = @_;

    return $self->error('EditURI and title are both required')
        unless $EditURI || $param{title};

    my $entry = WebService::Hatena::Fotolife::Entry->new;
       $entry->title($param{title});
       $entry->generator($param{generator}) if $param{generator};

    if ($param{folder}) {
        my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
        $entry->set($dc, 'subject', $param{folder});
    }

    if ($param{lat} or $param{lon}) {
        my $georss = XML::Atom::Namespace->new(georss => GEORSS);
        $entry->set($georss, 'point', $param{lat} . ' ' . $param{lon});
    }

    $self->SUPER::updateEntry($EditURI, $entry);
}

sub munge_request {
    my $self    = shift;
    my $req     = shift;
    my $headers = [@{ $self->{headers} }];

    $self->SUPER::munge_request($req);
    while (my ($key, $value) = splice @$headers, 0, 2) {
        $req->header($key => $value);
    }

    $req;
}

sub munge_response {
    my $self = shift;
    my $res  = shift;

    my $status = $res->header('Status');
    if ($status and $status =~ s/^(\d+)\s+(?=.+)//) {
        $res->code($1);
        $res->message($status);
    }

    $self->SUPER::munge_response($res, @_);
}

sub getFeed {
    my $self = shift;
       $self->SUPER::getFeed($FeedURI);
}

sub _get_image {
    my ($self, $image_source) = @_;
    my $image;

    if (ref $image_source eq 'SCALAR') {
        $image = $image_source;
    }
    else {
        $image = do {
            local $/ = undef;
            my $fh = FileHandle->new($image_source)
                or return $self->error("can't open $image_source: $!");
            my $content = <$fh>;
            \$content;
        };
    }

    my $info  = Image::Info::image_info($image);
    return $self->error($info->{error})
        if $info->{error} and $info->{error} !~ /short read/;

    +{
        content      => $image,
        content_type => $info->{file_media_type},
    };
}

1;

__END__

=head1 NAME

WebService::Hatena::Fotolife - A Perl interface to the
Hatena::Fotolife Atom API

=head1 SYNOPSIS

  use WebService::Hatena::Fotolife;

  my $fotolife = WebService::Hatena::Fotolife->new;
     $fotolife->username($username);
     $fotolife->password($password);

  # create a new entry with image filename
  my $EditURI = $fotolife->createEntry(
      title    => $title,
      filename => $filename,
      folder   => $folder,
  );

  # or specify the image source as a scalarref
  my $EditURI = $fotolife->createEntry(
      title     => $title,
      scalarref => \$image_content,
      folder    => $folder,
  );

  # update the entry
  $fotolife->updateEntry($EditURI, title => $title);

  # delete the entry
  $fotolife->deleteEntry($EditURI);

  # retrieve the feed
  my $feed = $fotolife->getFeed;
  my @entries = $feed->entries;
  ...

=head1 DESCRIPTION

WebService::Hatena::Fotolife provides an interface to the
Hatena::Fotolife Atom API.

This module is a subclass of L<XML::Atom::Client>, so see also the
documentation of the base class for more usage.

=head1 METHODS

=head2 new

=over 4

  my $fotolife = WebService::Hatena::Fotolife->new;

Creates and returns a WebService::Hatena::Fotolife object.

=back

=head2 createEntry ( I<%param> )

  # passing an image by filename
  my $EditURI = $fotolife->createEntry(
      title    => $title,
      filename => $filename,
  );

  # or...

  # a scalar ref to the image content
  my $EditURI = $fotolife->createEntry(
      title     => $title,
      scalarref => $scalarref,
  );

Uploads given image to Hatena::Fotolife. Pass in the image source as a
filename or a scalarref to the image content. There're some more
options described below:

=over 4

=item * title

Title of the image.

=item * filename

Local filename of the image.

=item * scalarref

Scalar reference to the image content itself.

=item * folder

Place, called "folder" in Hatena::Fotolife, you want to upload your
image.

=item * generator

Specifies generator string. Hatena::Fotolife can handle your request
along with it. See L<http://f.hatena.ne.jp/my/config> for detail.

=back

=head2 updateEntry ( I<$EditURI>, I<%param> )

  my $EditURI = $fotolife->updateEntry(
      $EditURI,
      title => $title,
  );

Updates the title of the entry at I<$EditURI> with given
options. Hatena::Fotolife Atom API currently doesn't support to update
the image content directly via Atom API.

=head2 getFeed

  my $feed = $fotolife->getFeed;

Retrieves the feed. The count of the entries the I<$feed> includes
depends on your configuration of Hatena::Fotolife.

=head2 use_soap ( I<[ 0 | 1 ]> )

=head2 username ( [ I<$username ]> )

=head2 password ( [ I<$password ]> )

=head2 getEntry ( I<$EditURI> )

=head2 deleteEntry ( I<$EditURI> )

See the documentation of the base class, L<XML::Atom::Client>.

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

Copyright (C) 2005 - 2010 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
