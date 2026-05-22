sub init()
    m.top.functionName = "loadFirestore"
end sub

sub loadFirestore()
    projectId = m.top.projectId
    if projectId = ""
        m.top.errorMessage = "Firestore config is missing."
        return
    end if
    baseUrl = "https://firestore.googleapis.com/v1/projects/" + projectId + "/databases/(default)/documents/"
    if m.top.requestType = "increment"
        if m.top.documentName = ""
            m.top.errorMessage = "Firestore increment document is missing."
            return
        end if
        if m.top.fieldPath = "" then
            m.top.fieldPath = "viewCount"
        end if
        url = "https://firestore.googleapis.com/v1/projects/" + projectId + "/databases/(default)/documents:commit"
    else if m.top.requestType = "collectionGroup"
        if m.top.queryCollection = ""
            m.top.errorMessage = "Firestore query collection is missing."
            return
        end if
        url = "https://firestore.googleapis.com/v1/projects/" + projectId + "/databases/(default)/documents:runQuery"
    else if m.top.requestType = "collection"
        if m.top.collectionPath = ""
            m.top.errorMessage = "Firestore collection path is missing."
            return
        end if
        ' Keep the collection request simple while testing. Firestore can reject
        ' orderBy if a document is missing that field.
        url = baseUrl + m.top.collectionPath
    else
        if m.top.documentPath = ""
            m.top.errorMessage = "Firestore document path is missing."
            return
        end if
        url = baseUrl + m.top.documentPath
    end if
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    if m.top.requestType = "increment"
        request.AddHeader("Content-Type", "application/json")
        body = buildIncrementBody(m.top.documentName, m.top.fieldPath)
        response = request.PostFromString(body)
    else if m.top.requestType = "collectionGroup"
        request.AddHeader("Content-Type", "application/json")
        body = buildCollectionGroupBody(m.top.queryCollection)
        response = request.PostFromString(body)
    else
        response = request.GetToString()
    end if
    if response = invalid
        m.top.errorMessage = "Firestore request returned no data."
        return
    end if
    responseType = Type(response)
    if responseType <> "roString" and responseType <> "String"
        m.top.errorMessage = "Firestore request did not return JSON."
        return
    end if
    if response = ""
        m.top.errorMessage = "Firestore request returned no data."
        return
    end if
    parsed = ParseJson(response)
    if parsed = invalid
        m.top.errorMessage = "Firestore response was not valid JSON."
        return
    end if
    if Type(parsed) = "roAssociativeArray" and parsed.error <> invalid
        if parsed.error.message <> invalid
            m.top.errorMessage = "Firestore error: " + parsed.error.message
        else
            m.top.errorMessage = "Firestore request failed."
        end if
        return
    end if
    if m.top.requestType = "increment"
        m.top.resultData = {
            ok: true
        }
    else if m.top.requestType = "collectionGroup"
        m.top.resultData = parseFirestoreRunQuery(parsed)
    else if m.top.requestType = "collection"
        m.top.resultData = parseFirestoreCollection(parsed)
    else
        m.top.resultData = parseFirestoreDocument(parsed)
    end if
end sub

function buildCollectionGroupBody(collectionId as string) as string
    return "{""structuredQuery"":{""from"":[{""collectionId"":""" + collectionId + """,""allDescendants"":true}]}}"
end function

function buildIncrementBody(documentName as string, fieldPath as string) as string
    return "{""writes"":[{""transform"":{""document"":""" + documentName + """,""fieldTransforms"":[{""fieldPath"":""" + fieldPath + """,""increment"":{""integerValue"":""1""}}]}}]}"
end function

function parseFirestoreRunQuery(response as dynamic) as object
    result = {
        items: []
    }
    if response = invalid or Type(response) <> "roArray"
        return result
    end if
    for each row in response
        if row.document <> invalid
            result.items.Push(parseFirestoreDocument(row.document))
        end if
    end for
    return result
end function

function parseFirestoreCollection(response as object) as object
    result = {
        items: []
    }
    if response = invalid or response.documents = invalid
        return result
    end if
    for each document in response.documents
        result.items.Push(parseFirestoreDocument(document))
    end for
    return result
end function

function parseFirestoreDocument(document as object) as object
    result = {}
    if document = invalid
        return result
    end if
    if document.name <> invalid
        result.path = document.name
        pathParts = document.name.Split("/")
        result.id = pathParts[pathParts.Count() - 1]
        result.hostId = getHostIdFromPath(pathParts)
    end if
    if document.fields = invalid
        return result
    end if
    for each fieldName in document.fields
        result[fieldName] = getFirestoreValue(document.fields[fieldName])
    end for
    return result
end function

function getHostIdFromPath(pathParts as object) as dynamic
    if pathParts = invalid then
        return invalid
    end if
    for i = 0 to pathParts.Count() - 2
        if pathParts[i] = "channels"
            return pathParts[i + 1]
        end if
    end for
    return invalid
end function

function getFirestoreValue(field as object) as dynamic
    if field = invalid
        return invalid
    end if
    if field.stringValue <> invalid
        return field.stringValue
    else if field.integerValue <> invalid
        return field.integerValue
    else if field.doubleValue <> invalid
        return field.doubleValue
    else if field.booleanValue <> invalid
        return field.booleanValue
    else if field.timestampValue <> invalid
        return field.timestampValue
    else if field.arrayValue <> invalid
        values = []
        if field.arrayValue.values <> invalid
            for each item in field.arrayValue.values
                values.Push(getFirestoreValue(item))
            end for
        end if
        return values
    else if field.mapValue <> invalid
        value = {}
        if field.mapValue.fields <> invalid
            for each mapFieldName in field.mapValue.fields
                value[mapFieldName] = getFirestoreValue(field.mapValue.fields[mapFieldName])
            end for
        end if
        return value
    end if
    return invalid
end function'//# sourceMappingURL=./FirestoreTask.bs.map