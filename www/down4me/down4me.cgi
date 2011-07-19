#!/usr/bin/perl -w

print "Content-type: text/html\n\n"; 

header();
print "<tr><td>getting sim.gif</td></tr>";
`cd files; wget http://saulo.mine.nu/sim.gif/; cd ..`;
print "<tr><td><pre>"; print `cd files;ls`; print "</pre></tr></td>";
foot();

sub header {
print <<HTML
	<html>
	<head>
	<meta http-equiv="Content-Language" content="pt-br">
	<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
	<title>DNA Cypher</title>
	</head>
	<body bgcolor="EEEEEE" text="black" link="#FFFFFF" vlink="#FF0000" alink="#FFFF00">
	<center>
	<table border="1" bordercolor="black" cellpadding="0" cellspacing="0">

	<tr bgcolor="black">
		<td align="centeR"><font size="5" face="verdana" color="white"><B>Down4Me</B></font></td>
	</tr>
HTML
;
};



sub foot {
print <<HTML
	<br>
	<tr bgcolor="black">
		<td align="right"><small><font size="2" face="verdana" color="white">Down4Me by Saulo Alves</font></small></td>
        </tr>
	</table>
	</body></html>
HTML
;
};






