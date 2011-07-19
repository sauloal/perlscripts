<html>

<head>
<meta http-equiv="Content-Language" content="en-us">
<meta name="GENERATOR" content="Microsoft FrontPage 5.0">
<meta name="ProgId" content="FrontPage.Editor.Document">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<title>--== Saulo @ Home :: Down4Me ==--</title>
</head>

<body link="#FF0000" vlink="#FFFF00" alink="#00FF00" topmargin="0" leftmargin="0" text="#FFFFFF" bgcolor="#000000">


<?php
$request = $_GET['request'];

if ($request)
{
	pclose(popen("wget -b -q -P ..\\..\\upload -o log.log \"$request\"", "r"));
}

?>


<div align="center">
  <center>
  <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" width="250" id="AutoNumber1">
<form method="GET" name="formulare" action="index.php">
    <tr>
      <td colspan="2">
      <p align="center"><b><font size="6">Down4Me</font></b></td>
    </tr>
    <tr>
      <td colspan="2">
      <b><font size="4">
<?php
	if ($request)
	{
		echo "Downloaded: " . $request;
		echo "<br>\n";
		echo "Check on <a href=\"../../upload\">Uploaded Folder</a>\n";
	}
?>



</font></b></td>
    </tr>
    <tr>
      <td><input type="text" name="request" size="50"></td>
      <td><input type="submit" value="Submit"></td>
    </tr>
  </form>
  </table>
  </center>
</div>
</body>

</html>