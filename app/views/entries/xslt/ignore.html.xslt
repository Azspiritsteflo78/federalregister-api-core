<?xml version="1.0" encoding="ISO-8859-1" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Tags being Ignored -->
  <xsl:template match="AGENCY | SUBAGY| AGY[count(child::P) &lt; 2] | CFR | DEPDOC | RIN | SUBJECT | CNTNTS | UNITNAME | INCLUDES | EDITOR | EAR | FRDOCBP | HRULE | FTREF | NOLPAGES | OLPAGES | SECHD | TITLE3 | PRES | NOPRINTSUBJECT | NOPRINTEONOTES">
  </xsl:template>
</xsl:stylesheet>
