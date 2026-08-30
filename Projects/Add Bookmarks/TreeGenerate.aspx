<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="utf-8" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Notes Directory Navigator</title>
    <style>
        body { font-family: sans-serif; line-height: 1.5; margin: 20px; }
        ul { list-style-type: none; padding-left: 0; }
        li { margin: 5px 0; }
        .folder { font-weight: bold; color: #0066cc; }
        .file { color: #333333; }
        .parent { font-style: italic; color: #555555; }
        a { text-decoration: none; }
        a:hover { text-decoration: underline; }
        .breadcrumb { font-size: 1.1em; margin-bottom: 20px; padding: 5px; background: #eee; }
    </style>
</head>
<body>

    <h2>Notes Directory Navigator</h2>

    <%
        // 1. Change rootPath to point to your specific subfolder
        string rootPath = Server.MapPath("~/uploads/notes/");
        
        // 2. Get the requested path from the query string, default to root
        string reqPath = Request.QueryString["dir"];
        string currentPath = rootPath;

        if (!string.IsNullOrEmpty(reqPath))
        {
            // Combine and resolve the full physical path safely
            currentPath = Path.GetFullPath(Path.Combine(rootPath, reqPath));
        }

        // Ensure currentPath also ends with a separator if it's a directory to keep comparisons uniform
        if (!currentPath.EndsWith(Path.DirectorySeparatorChar.ToString()))
        {
            currentPath += Path.DirectorySeparatorChar;
        }

        // 3. Security Check: Prevent Directory Traversal (Stops them going above \uploads\notes\)
        if (!currentPath.StartsWith(rootPath, StringComparison.OrdinalIgnoreCase))
        {
            currentPath = rootPath; 
        }

        // 4. Safe Relative Path Calculation using Uri
        Uri rootUri = new Uri(rootPath);
        Uri currentUri = new Uri(currentPath);
        string relPath = rootUri.MakeRelativeUri(currentUri).ToString().Replace('/', Path.DirectorySeparatorChar);
        relPath = Uri.UnescapeDataString(relPath).TrimEnd(Path.DirectorySeparatorChar);
    %>

    <div class="breadcrumb">
        <strong>Current Path:</strong>/<%= relPath.Replace(Path.DirectorySeparatorChar, '/') %>
    </div>

    <ul>
        <%-- Up to Parent Directory Link --%>
        <% if (currentPath.TrimEnd(Path.DirectorySeparatorChar) != rootPath.TrimEnd(Path.DirectorySeparatorChar)) { 
            string parentDir = Path.GetDirectoryName(currentPath.TrimEnd(Path.DirectorySeparatorChar));
            string parentRel = parentDir.Substring(rootPath.Length).TrimStart(Path.DirectorySeparatorChar);
            string parentUrl = string.IsNullOrEmpty(parentRel) ? "" : HttpUtility.UrlEncode(parentRel);
        %>
            <li class="parent">&#128193; <a href="?dir=<%= parentUrl %>">[.. Up to Parent]</a></li>
        <% } %>

        <%-- List Directories --%>
        <% 
            try 
            {
                string[] directories = Directory.GetDirectories(currentPath);
                foreach (string dir in directories)
                {
                    DirectoryInfo di = new DirectoryInfo(dir);
                    string nextRelPath = Path.Combine(relPath, di.Name);
                    string encodedPath = HttpUtility.UrlEncode(nextRelPath);
        %>
                    <li class="folder">&#128193; <a href="?dir=<%= encodedPath %>"><%= HttpUtility.HtmlEncode(di.Name) %>/</a></li>
        <% 
                }
            }
            catch (Exception ex) 
            {
                Response.Write("<li style='color:red;'>Error reading directories: " + HttpUtility.HtmlEncode(ex.Message) + "</li>");
            }
        %>

        <%-- List HTML Files Only --%>
        <% 
            try 
            {
                string[] files = Directory.GetFiles(currentPath, "*.*")
                                          .Where(f => f.EndsWith(".html", StringComparison.OrdinalIgnoreCase) || 
                                                      f.EndsWith(".htm", StringComparison.OrdinalIgnoreCase))
                                          .ToArray();
                
                foreach (string file in files)
                {
                    string fileName = Path.GetFileName(file);
                    // Map the file path back to a web URL relative to the uploads folder
                    string fileWebPath = "~/uploads/notes/" + Path.Combine(relPath, fileName).Replace(Path.DirectorySeparatorChar, '/');
        %>
                    <li class="file">&#128196; <a href="<%= ResolveUrl(fileWebPath) %>" target="_blank"><%= HttpUtility.HtmlEncode(fileName) %></a></li>
        <% 
                }
            }
            catch (Exception ex) 
            {
                Response.Write("<li style='color:red;'>Error reading files: " + HttpUtility.HtmlEncode(ex.Message) + "</li>");
            }
        %>
    </ul>

</body>
</html>