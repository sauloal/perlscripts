#!/usr/bin/perl
 
# This is code example 4 in the Graphics-HOWTO
use strict;
use lib "$ENV{HOME}/projects/bioperl-live";
use Bio::Graphics;
use Bio::SearchIO;
use Bio::Search::Result::BlastResult;
 
my $file = shift or die "Usage: $0 <blast file>\n";
 
my $searchio = Bio::SearchIO->new(-file   => $file,
                                  -format => 'blast') or die "parse failed";

# my $obj = Bio::Search::Result::BlastResult->new();

my $panel = Bio::Graphics::Panel->new(
									-length    => 34790,
									-width     => 800,
									-pad_left  => 10,
									-pad_right => 10,
									);

my $full_length = Bio::SeqFeature::Generic->new(
												-start        => 1,
												-end          => 34790,
												-display_name => "CHROMOSSOME 25 - MITOCHONDRIAL GENOME",
											);
$panel->add_track($full_length,
				-glyph   => 'arrow',
				-tick    => 2,
				-fgcolor => 'black',
				-double  => 1,
				-label   => 1,
				);
 
while (my $result = $searchio->next_result())
{
# 	my $result = $searchio->next_result() or die "no result";
 
	my $track = $panel->add_track(
								-glyph       => 'graded_segments',
								-label       => 1,
								-connector   => 'dashed',
								-bgcolor     => 'blue',
								-font2color  => 'red',
								-sort_order  => 'high_score',
								-description => sub {
									my $feature = shift;
									return unless $feature->has_tag('description');
									my ($description) = $feature->each_tag_value('description');
									my $score = $feature->score;
									"$description, score=$score";
								},
								);
	
	while( my $hit = $result->next_hit ) {
		next unless $hit->significance < 1E-50;
		my $feature = Bio::SeqFeature::Generic->new(
													-score        => $hit->raw_score,
													-display_name => $result->query_name . " (" . $hit->start('hit') . ":" . $hit->end('hit') .")",
# 													-tag          => {
# 																		description => $hit->description
# 																	},
# 													-start        => $hit->start('hit'),
# 													-end          => $hit->end('hit'),
													);
# 		while( my $hsp = $hit->next_hsp ) {
		my $hsp = $hit->next_hsp;
			my $sub_feature = Bio::SeqFeature::Generic->new(
													-score        => $hsp->score,
													-display_name => $result->query_name . " (" . $hsp->start('hit') . ":" . $hsp->end('hit') .")",
# 													-tag          => {
# 																		description => $hit->description
# 																	},
													-start        => $hsp->start('hit'),
													-end          => $hsp->end('hit'),
													);
			$feature->add_sub_SeqFeature($sub_feature, 'EXPAND');
# 		}
		

# 			my $cov = Bio::SeqFeature::Generic->new(
# 							-start        =>$start,
# 							-end          =>$cov{$start},
# # 							-display_name =>"coverage"
# 							);
# 			$track->add_feature($cov);

		$track->add_feature($feature);
	}
}

	open FILE, ">$file.png" or die "COULD NOT SAVE PNG";
	print FILE $panel->png;
	close FILE;
1;
