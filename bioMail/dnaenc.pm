#!/usr/bin/perl
use lib "./lib";
use loadconf;
my %pref = &loadconf::loadConf;
package dnacypherENC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dnacypherENC);
our $DESCRIPTION="converts a text into dna";

###################################################################
###             DNA CYPHER                                      ###
### by MeowChow (c&#65533;digo) e Saulo Alves (front end)              ###
### primeira versao do codigo: 2002                             ###
### primeira versao do front-end: 01/2003                       ###
### vers&#65533;o atual: 2.0 (2006-02-19@2355)                         ###
###                                                             ###
###################################################################

# print "Content-type: text/html\n\n";
# header(); # cabecalho HTML
# getform(); # obtem os dados enviados pelo formulario
# foot(); # coloca o rodape do HTML


sub dnacypherENC
{
    my $input = $_[0]; #body of the incoming message untreated

        my $output = dnaencoder($input);
#         my $output = dnadecoder($input);

    return $output; #body of the outgoing message untreated
}






###############################################################
################ DECODIFICA O TEXTO EM DNA ####################
###############################################################
sub dnadecoder{
        $_ = $_[0]; # pegue o texto a ser codificado
#         if ($info{'Formato'} eq "Cadeia") {
#                 print "<p><textarea rows=\"8\" name=\"TranscritoCadeia\" cols=\"85\" tabindex=\"5\">";
# 
#                 $_ =~ s/\r/\r\n/g; # substitua o retorno de carro (linux) por retorno de carro + enter (windows)
#                 $_ .= "\r\n "; # coloque um retorno de carro + enter no final do texto
# 
#                 $contador = 0; # Zere o contador
#                 @_{A=> C=> G=> T=>}=0..3; # atribua o valor a cada uma das letras
# 
#                 $_ =~ s/.*(\w).*(\w).*\n/$_{$contador++\/8%2?$2:$1}/gex;
#                         # vamos por partes:
#                         # pegue uma letra antecedida por caracteres e salve como $1,
#                         # pegue a proxima letra antecedida por caracteres+letra($1)+caracteres+enter
#                         # e seguida de caracteres e salve essa segunda letra como $2
#                         # substitua a sentenca toda (caracteres+letra[$1]+caracteres+letra[$2]+caracteres+enter
#                         # se o numero da linha for divizivel por 8 ($contador/8%2 => se na divisao nao houver resto)
#                         # significa que estamos no lado externo da fita (primeira volta) e usaremos o $2
#                         # .. se nao for divizivel (houver resto) significa que estamos no lado interno da fita...
#                         # entao usa-se o $1
#                         # uma vez decidido qual nucleotideo ler, substitua ele pelo seu respectivo numero $_[n]
#         };


    $_ =~ s/\r//g; # substitua o retorno de carro (linux) por nada
    $_ =~ s/\n//g; # substitua o enter por nada
    $_ =~ tr/ACGT/0123/;


        $_ =~ s/(.)(.)(.)(.)/chr(64*$1+16*$2+4*$3+$4)/gex;
                # sigamos os conselhos do s&#65533;bio jack.. vamos por partes aqui tb
                # como cada letra eh substituida por 4 nucleotideos, pege de 4 em 4 numeros
                # e multiplique o primeiro por 64, o segundo por 16, o terceiro por 4 e o ultimo
                # por 1.. teremos assim a reversao da emcriptacao do codigo ascii em base 4

        return $_;
}





###############################################################
################# CODIFICA O TEXTO EM DNA #####################
###############################################################
sub dnaencoder{
        my $str  = $_[0];
        my $BASE = 4;
        my %NUC_PAIRS = (
          A => T =>
          C => G =>
          G => C =>
          T => A =>
        );

        my @DIGIT_TO_NUC = qw( A C G T );

my $FMT_DNA = <<END;
 01
0--1
0---1
0----1
 0----1
  0---1
   0--1
    01
    10
   1--0
  1---0
 1----0
1----0
1---0
1--0
 10
END
        my @FMT_DNA = split "\n",$FMT_DNA; # separa a fita colocando cada linha em um array

        my @str_digits;
        for (split//, $str) { # separa a palavra a ser codificada letra por letra
                my $ord = ord($_); # obtem o codigo ascII da letra
                my @digits = (0) x 4; # cria o array @digits composto de 4 zeros
#               print "$ord:\t"; # imprime na tela o codigo ascII da letra
                my $i = 0; 
                while ($ord) { # loop para decompor o numero ascII em base 4
                               # por divisoes sucessivas ate se obter o resto 0
                        $digits[4 - ++$i] = $ord % $BASE;
                        $ord = int ($ord / $BASE);
                }
#               print "@digits\n"; @ imprime o codigo ascII transformado em base 4
                push @str_digits, [@digits];    # salva todos os codigos ascII em base
                                                # 4 gerados no array. cada elemento deste
                                                # array ser&#65533; um outro array de 4 elementos..
        }

        my $i = 0;
        my $adn;
    my $cadeia = "";
    my $fasta  = "";

        for (@str_digits) {     # para cada codigo ascII em base 4 gerado
                                # (4 digitos para cada letra do texto original)
                for (@$_) {     # obtenha os 4 digitos q compoe o codigo relativo a 1 letra
                        my $fmt = $FMT_DNA[$i++ % @FMT_DNA];    # decide qual linha da dupla helice
                                                                # deve-se ler vendo qual o resto para o
                                                                # multiplo do total de linhas da helice 
                        my $nuc0 = $DIGIT_TO_NUC[$_]; # retorna o nucleotideo relativo ao numero
                        $adn .= $nuc0; # salva sequencialmente os nucleotideos
                        my $nuc1 = $NUC_PAIRS{$nuc0}; # verifica o nucleotideo que pareia
                        $fmt =~ s/0/$nuc0/; # substitui o 0 pelo nucleotideo de valor
                        $fmt =~ s/1/$nuc1/; # substitui o 1 pelo nucleotideo emparelhante
                        $cadeia .= "$fmt\n"; #imprime a linha atual da cadeia
                }
        }

    my $I = 0;
        while ($I <= (int(length($adn) / 80)))
    { # imprima no formato FASTA
                $fasta .= substr($adn,($I++*80),80) . "\n";
        };

    return "$fasta\n$cadeia";
}

1;