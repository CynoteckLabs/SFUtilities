Attribute VB_Name = "CustomMetadataUtility"
Sub convertCustomMetadataRecords()
Attribute convertCustomMetadataRecords.VB_ProcData.VB_Invoke_Func = " \n14"
' generate custom metadata data files for upload
    
    Dim sh As Worksheet
    Dim rw As Range
    Dim RowCount As Integer
    RowCount = 1
    
    Dim arrApiNames() As String
    
    Dim folderPath As String
    
    'default value
    folderPath = InputBox("Enter File path", "Cynoteck Metdata Generator", "")
    
    If Trim(folderPath) = "" Then
        folderPath = ActiveWorkbook.Path
    End If
    
    Dim strMetadataName As String
    
    strMetadataName = InputBox("Enter Metadata name", "Cynoteck Metdata Generator", "")
    
    Dim arrFiles As New Collection
    
    If Trim(strMetadataName) <> "" Then
        For Each rw In ActiveSheet.UsedRange.Rows
            ' if no data-> exit for loop
            If ActiveSheet.Cells(rw.row, 1).value = "" Then
                Exit For
            End If
            
            If RowCount = 1 Then
                'extract field api names
                arrApiNames = readHeader(rw.row)
            Else
                'generate files
                Dim fileName As String
                fileName = strMetadataName & "." & StringHelper.replaceSpecialChars(ActiveSheet.Cells(rw.row, 1).value, "_")
                
                createCustomMetadataFile rw.row, fileName, folderPath, arrApiNames, True
                        
                arrFiles.Add (fileName)
            End If
            
            RowCount = RowCount + 1
        
        Next rw
        
        MsgBox RowCount & " Custom Metadata Files generated successfully", vbOKOnly, "Cynoteck Utility"
    Else
        MsgBox "No Custom Metadata name provided. Exiting Process.", vbOKOnly, "Cynoteck Utility"
    End If
    
    generatePackageFile arrFiles, folderPath
End Sub

Function readHeader(rowNum As Integer) As String()
    Dim jointValues As String
    Dim cellNum As Integer
    cellNum = 1
    
    While ActiveSheet.Cells(rowNum, cellNum).value <> ""
        If Len(jointValues) > 0 Then
            jointValues = jointValues & " "
        End If
        jointValues = jointValues & ActiveSheet.Cells(rowNum, cellNum).value
        cellNum = cellNum + 1
    Wend
    
    readHeader = Split(jointValues, " ")
End Function

Sub createCustomMetadataFile(rowNum As Integer, fileName As String, location As String, ByRef arrApiNames() As String, protected As Boolean)
Attribute createCustomMetadataFile.VB_ProcData.VB_Invoke_Func = " \n14"
    Dim apiName As Variant
    Dim sFile As String
    sFile = location & "\" & fileName & ".md"
    
   'Create new metadata file for output
    Open sFile For Output As #1
        Print #1, "<?xml version=""1.0"" encoding=""UTF-8""?>"
        Print #1, "<CustomMetadata xmlns=""http://soap.sforce.com/2006/04/metadata"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" >"
        Print #1, "     <label>" & ActiveSheet.Cells(rowNum, 1).value & "</label>"
        Print #1, "     <protected>" & protected & "</protected>"
        
        Dim fieldNum As Integer
        fieldNum = 1
        
        ' loop through each cell to retrieve api name and value to generate value nodes
        For Each apiName In arrApiNames
        
            If fieldNum > 1 Then
                'skip first column as it contains record label
                Print #1, createValueFieldNode(apiName, ActiveSheet.Cells(rowNum, fieldNum).value)
            End If
            
            fieldNum = fieldNum + 1
        Next apiName
        
        Print #1, "</CustomMetadata>"
    Close
    
End Sub

Function createValueFieldNode(apiName As Variant, value As Variant) As String
    Dim nodeVal As String
    nodeVal = nodeVal & "     <values>" & vbCrLf
    nodeVal = nodeVal & "          <field>" & apiName & "</field>" & vbCrLf
    nodeVal = nodeVal & "          <value xsi:type=""xsd:string"">" & value & "</value>" & vbCrLf
    nodeVal = nodeVal & "     </values>"
    
    createValueFieldNode = nodeVal
End Function

Sub generatePackageFile(ByRef arrFiles As Collection, folderPath As String)

    Dim sFile As String
    sFile = folderPath & "\package.xml"
    
   'Create new metadata file for output
    Open sFile For Output As #1
        Print #1, "<?xml version=""1.0"" encoding=""UTF-8""?>"
        Print #1, "<Package xmlns=""http://soap.sforce.com/2006/04/metadata"">"
        Print #1, " <types>"
        
        Dim count As Integer
        count = 1
        While count < arrFiles.count
            Print #1, "<members>" & arrFiles.Item(count) & "</members>"
            count = count + 1
        Wend
        Print #1, " </types>"
        Print #1, "<version>42.0</version>"
    Close
End Sub
