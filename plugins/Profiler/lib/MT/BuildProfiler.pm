package MT::BuildProfiler;

# TODO Turn this utility library into a real object-oriented class

use strict;
use warnings;
use MT::Util qw( epoch2ts );
use Time::HiRes;
use Data::Dumper;

# TODO Get rid of package variables in favor of object properties
our ( %PROFILES, $BUILD_START_AT, $BUILD_ELAPSED, %EXDATA );

sub report {
    Data::ObjectDriver->profiler->reset;
    my $driver      = MT::Object->driver;
    my $total_time  = 0;
    my $total_query = 0;
    my @tags = sort { $PROFILES{$b}{time} <=> $PROFILES{$a}{time} }
                      keys %PROFILES;

    my @rows;
    foreach my $tag ( @tags ) {

        # my $queries = $PROFILES{$tag}{queries} || [];
        my $time_avg = sprintf( "%0.3f",
            $PROFILES{$tag}{time} / $PROFILES{$tag}{calls} );
        my $queries     = $PROFILES{$tag}->{queries};
        my $ramhit      = map { $_ =~ m/RAMCACHE_GET/ } @$queries;
        my $ramadd      = map { $_ =~ m/RAMCACHE_ADD/ } @$queries;
        my $query_count = scalar(@$queries) - ( $ramhit + $ramadd );
        push @rows,
          {
            time    => sprintf( "%0.3f", $PROFILES{$tag}{time} ),
            tag     => $tag,
            calls   => $PROFILES{$tag}{calls},
            avg     => $time_avg,
            queries => $query_count,
            hits    => $ramhit,
            misses  => $ramadd,
          };
        $total_time  += $PROFILES{$tag}{time};
        $total_query += $query_count;

        # Restore D::OD query profile so the report we will generate
        # from it will be right:
        Data::ObjectDriver->profiler->record_query( $driver, $_ )
            foreach @$queries;

    } ## end foreach my $tag ( sort { $PROFILES...})

    return @rows;

} ## end sub report

sub install {
    my $all_tags = MT::Component->registry("tags");
    for my $tag_set (@$all_tags) {
        for my $type (qw( block function )) {
            my $tags = $tag_set->{$type} or next;
            for my $tagname ( keys %$tags ) {
                $tags->{$tagname} = _make_tracker( $tags->{$tagname} );
            }
        }
    }
}

sub _make_tracker {
    my $original_method = shift;
    return sub {
        my ( $ctx, $args, $cond ) = @_;
        my $tagname = lc $ctx->stash('tag');
        pre_process_tag( $ctx, $args, $cond );
        my $meth = MT->handler_to_coderef($original_method)
          unless $original_method eq 'CODEREF';
        my $res = $meth->( $ctx, $args, $cond );
        post_process_tag($res);
        return $res;
    };
}

{
    my $CURRENT_TAG;
    my @PROFILE_STACK;

    sub pre_process_tag {
        my ( $ctx, $args, $cond ) = @_;
        $BUILD_START_AT = [ Time::HiRes::gettimeofday() ]
          unless defined $BUILD_START_AT;
        if ( defined $CURRENT_TAG ) {
            $CURRENT_TAG->pause;
            push @PROFILE_STACK, $CURRENT_TAG;
        }
        my $tagname = lc $ctx->stash('tag');
        $CURRENT_TAG = TagProfiler->new($tagname);
    }

    sub post_process_tag {
        my ($res) = @_;
        $CURRENT_TAG->end;

        #save results to hash
        my $results = $PROFILES{ $CURRENT_TAG->{tagname} };
        if ( defined $results ) {
            $results->{calls} += 1;
            $results->{time}  += $CURRENT_TAG->{time};
            push @{ $results->{queries} }, @{ $CURRENT_TAG->{queries} };
        }
        else {
            $PROFILES{ $CURRENT_TAG->{tagname} } = {
                                           calls   => 1,
                                           time    => $CURRENT_TAG->{time},
                                           queries => $CURRENT_TAG->{queries},
            };
        }
        $CURRENT_TAG = pop @PROFILE_STACK;
        $CURRENT_TAG->resume if defined $CURRENT_TAG;
        $BUILD_ELAPSED = Time::HiRes::tv_interval($BUILD_START_AT);
    } ## end sub post_process_tag
}

package TagProfiler;

use strict;
use Time::HiRes;
use Data::ObjectDriver;

sub new {
    my $class       = shift;
    my ( $tagname ) = @_;
    my $now         = [ Time::HiRes::gettimeofday() ];
    Data::ObjectDriver->profiler->reset;
    return bless {  tagname => $tagname,
                    last => $now,
                    time => 0,
                    queries => []
            }, $class;
}

sub pause {
    my $self = shift;
    $self->{time} += Time::HiRes::tv_interval( $self->{last} );
    my $log = Data::ObjectDriver->profiler->query_log;

    $self->{queries} = [ @{ $self->{queries} }, @$log ]
        if ref $log eq 'ARRAY' and @$log;
}

sub resume {
    my $self = shift;
    $self->{last} = [ Time::HiRes::gettimeofday() ];
    Data::ObjectDriver->profiler->reset;
}

sub end {
    my $self = shift;
    $self->pause;
}

1;

__END__
