<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
    <ns uri="http://www.loc.gov/mads/rdf/v1#" prefix="madsrdf"/>
    <ns uri="http://ead3.archivists.org/schema/" prefix="ead"/>

    <!-- VARIABLES -->

    <!-- $language-code-lookups: array of urls of target codelist documents -->
    <xsl:variable name="language-code-lookups" as="element()*">
        <file key="iso639-1">http://id.loc.gov/vocabulary/iso639-1.rdf</file>
        <file key="iso639-2">http://id.loc.gov/vocabulary/iso639-2.rdf</file>
        <file key="iso639-3">http://anonscm.debian.org/gitweb/?p=iso-codes/pkg-iso-codes.git;a=blob_plain;f=iso_639_3/iso_639_3.xml</file>
    </xsl:variable>

    <!-- $doc is root of instance being tested -->
    <!--<let name="doc" value="/"/>-->
    
    <!-- active-language-code-key:
    get the value of the first conventiondeclaration/abbr whose content matches
    a @key in $language-code-lookups, with a fallback value of iso639-2 if 
    no language code is declared in a conventiondeclaration/abbr in the EAD3 document
    -->
    
    <let name="active-language-code-key" value="(/ead:ead/ead:control/@langencoding[.=$language-code-lookups/@key],'iso639-2')[1]"/>
    
    <!--$language-code-lookup:
     select <file> element from $language-code-lookups
     whose @key value matches the EAD3 document's first <conventiondeclaration> child 
     <abbr> element that declares the language codelist with any of the
     values of $language-code-lookups' @key attribute, with a fall-back of 'iso639-2'-->

    <let name="language-code-lookup"
        value="document($language-code-lookups[@key = $active-language-code-key])//madsrdf:code/normalize-space(.)  | document($language-code-lookups[@key = $active-language-code-key])//iso_639_3_entry/@id"/>

    <!-- CODES -->

    <pattern id="codes">

        <!-- LANGUAGE CODES -->
        <rule context="*[exists(@langcode | @lang)]">
            <let name="code" value="@lang | @langcode"/>
            <!-- for every @lang or @langcode attribute test that it is equal to a value in the language code list -->
            <assert
                test="every $l in (@lang | @langcode) satisfies normalize-space($l) = $language-code-lookup"
                > The <name/> element's lang or langcode attribute should contain a value from the <value-of select="$active-language-code-key"/> codelist. </assert>
        </rule>

        <!-- COUNTRY CODES -->

        <let name="countrycodes"
            value="document('country_names_and_code_elements_xml.xml')"/>
        <rule context="@countrycode">
            <let name="code" value="normalize-space(.)"/>
            <assert test="$countrycodes//ISO_3166-1_Alpha-2_Code_element/normalize-space(.) = $code"
                > The <name/> attribute should contain a code from the ISO 3166-1 codelist.
            </assert>
        </rule>

        <!-- SCRIPT CODES -->

        <let name="scriptcodes"
            value="document('http://anonscm.debian.org/gitweb/?p=iso-codes/iso-codes.git;a=blob_plain;f=iso_15924/iso_15924.xml;hb=HEAD')"/>
        <rule context="@scriptcode | @script">
            <let name="code" value="normalize-space(.)"/>
            <assert test="$scriptcodes//iso_15924_entry/@alpha_4_code = $code "> The <name/>
                attribute should contain a code from the iso_15924 codelist. </assert>
        </rule>
        
        <!-- REPOSITORY CODES -->
        
        <rule context="*[@repositorycode][preceding::ead:control/@repositoryencoding = 'iso15511']">
            <assert test="matches(@repositorycode, '(([A-Z]{2})|([a-zA-Z]{1})|([a-zA-Z]{3,4}))(-[a-zA-Z0-9:/\-]{1,11})')">
                If the repositoryencoding is set to iso15511, the <emph>repositorycode</emph> attribute of <name/> must be formatted as a iso15511 code.
            </assert>
        </rule>
        
    </pattern>

    <!-- Co-Occurrence-Constraints -->

    <pattern id="co-occurrence-constraints">
        <rule context="*[@level = 'otherlevel']">
            <assert test="normalize-space(@otherlevel)"> If the value of a <emph>level</emph> attribute is "otherlevel', then the <emph>otherlevel</emph> attribute must be used.
            </assert>
        </rule>
        <rule context="*[@physdescstructuredtype = 'otherphysdescstructuredtype']">
            <assert test="normalize-space(@otherphysdescstructuredtype)"> If the value of a <emph>physdescstructuredtype</emph> attribute is "otherphysdescstructuredtype', then the <emph>otherphysdescstructuredtype</emph> attribute must be used.
            </assert>
        </rule>
        <rule context="*[@daotype = 'otherdaotype']">
            <assert test="normalize-space(@otherdaotype)"> If the value of a <emph>daotype</emph> attribute is "otherdaotype', then the <emph>otherdaotype</emph> attribute must be used.
            </assert>
        </rule>
        <rule context="*[@dsctype = 'otherdsctype']">
            <assert test="normalize-space(@otherdsctype)"> If the value of a <emph>dsctype</emph> attribute is "otherdsctype', then the <emph>otherdsctype</emph> attribute must be used.
            </assert>
        </rule>
        <rule context="*[@otherrelation = 'otherrelationtype']">
            <assert test="normalize-space(@otherrelationtype)"> If the value of a <emph>otherrelation</emph> attribute is "otherrelationtype', then the <emph>otherrelationtype</emph> attribute must be used.
            </assert>
        </rule>
    </pattern>
    
    <!-- DATE NORMALIZATION -->
    
    <pattern id="dates">
        <rule context="ead:unitdate[@normal] | ead:date[@normal]">
            <assert test="matches(@normal, '(\-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|\-((01|02|03|04|05|06|07|08|09|10|11|12)(\-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)(/\-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|\-((01|02|03|04|05|06|07|08|09|10|11|12)(\-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)?')">
                The <emph>normal</emph> attribute of <name/> must be a iso8601 date.
            </assert>
        </rule>
    </pattern>
    
</schema>
