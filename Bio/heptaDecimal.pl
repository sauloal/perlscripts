my @DIGIT_TO_CODE = qw (0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ! @ $ % ^ * - _ = + ] [ } { ; : \ | > < . / ? ~ );
#                       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 
#                       0                   10                  20        25        30        35        40  42              50                  60                  70                  80        85
my %CODE_TO_DIGIT;
for (my $i = 0; $i < @DIGIT_TO_CODE; $i++)
{
    $CODE_TO_DIGIT{$DIGIT_TO_CODE[$i]} = $i;
}
my $BASE   = @DIGIT_TO_CODE;
my @digits = (undef) x $BASE;

sub digit2code
{
    my $number = $_[0];
    my @str_digits;
    @digits = (undef) x $BASE; #generates the array
    my $return = "";
    while ($number)
    {
        my $new = $DIGIT_TO_CODE[$number % $BASE];
        $return = "$new$return";
        $number = int($number / $BASE);
    }

    if ( $return eq "") {$return = 0;};
    return $return;

# CHROM 0 POS 1585 POS HEXA 631 POS CODE pz POS DECODE 2195 KEY 0 VALUE 3
#                                        ||-> 35 * 1  = 35
#                                        |--> 25 * 62 = 1550
#                                                       1585

# 5359 > =L
#        ||->47 * 1  = 47
#        |-->64 * 83 = 5312
#                      5359
}


sub code2digit
{
    my $digit = reverse($_[0]);

    my $result;
    my $power = 1;
    my $number;

    for (split (//, $digit))
    {
        $number  = $CODE_TO_DIGIT{$_};
        $number  = $number * $power;
        $result += $number;
        $power  *= $BASE;
    }

    return $result;
}