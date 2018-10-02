Attribute VB_Name = "StringHelper"
Function replaceSpecialChars(fileName As String, replaceString As String) As String
    
    replaceSpecialChars = Replace(fileName, "~", " ")
    
    replaceSpecialChars = Replace(replaceSpecialChars, "!", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "@", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "#", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "$", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "%", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "^", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "&", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "*", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "(", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, ")", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "-", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "\", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "/", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "{", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "}", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "|", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, ":", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, ";", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "'", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, """", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, ",", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "  ", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "?", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, ".", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, ">", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "<", " ")
    replaceSpecialChars = Replace(replaceSpecialChars, "`", " ")
    
    replaceSpecialChars = Replace(Trim(replaceSpecialChars), " ", replaceString)
    
End Function
