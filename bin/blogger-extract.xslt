<?xml version="1.0" encoding="UTF-8" standalone="yes"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:exsl="http://exslt.org/common" version="1.0" exclude-result-prefixes="xs html">
    <xsl:template match="/feed">
      <xsl:for-each select="entry">
        <exsl:document href="file_{@id}.xml">
          <title>
            <xsl:copy-of select="/feed/entry/title/@*" />
          </title>
        </exsl:document>
      </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>

