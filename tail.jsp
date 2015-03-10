<%--
  Created by IntelliJ IDEA.
  User: 1004lucifer
  Date: 2015. 3. 5.
  Time: 오후 9:51
--%>
<%@ page import="java.io.RandomAccessFile" %>
<%@ page import="java.io.FileNotFoundException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%
    String logPath = "/Users/btb/test/jsp/tail/";

    String fileName = request.getParameter("log_filename") == null ? "" : request.getParameter("log_filename");

    if ("".equals(fileName.trim()) == false) {

        fileName = logPath + fileName.trim().replaceAll("\\.\\.", "");

        long preEndPoint = request.getParameter("preEndPoint") == null ? 0 : Long.parseLong(request.getParameter("preEndPoint") + "");

        StringBuilder log = new StringBuilder();
        long startPoint = 0;
        long endPoint = 0;

        RandomAccessFile file = null;

        try {
            file = new RandomAccessFile(fileName, "r");
            endPoint = file.length();

            startPoint = preEndPoint > 0 ?
                            preEndPoint : endPoint < 2000 ?
                            0 : endPoint - 2000;

            file.seek(startPoint);

            String str;
            while ((str = file.readLine()) != null) {
                log.append(str);
                log.append("\n");
                endPoint = file.getFilePointer();
                file.seek(endPoint);
            }

        } catch (FileNotFoundException fnfe) {
            log.append("File does not exist.");
            fnfe.printStackTrace();
        } catch (Exception e) {
            log.append("Sorry. An error has occurred.");
            e.printStackTrace();
        } finally {
            try {file.close();} catch (Exception e) {}
        }

        out.print("{\"endPoint\":\"" + endPoint + "\", \"log\":\"" + URLEncoder.encode(new String(str.getBytes("ISO-8859-1"),"UTF-8"), "UTF-8").replaceAll("\\+", "%20") + "\"}");

    } else {


        List<String> fileList = new ArrayList<String>();
        String line = null;
        BufferedReader br = null;
        Process ps = null;
        try {
            Runtime rt = Runtime.getRuntime();
            ps = rt.exec(new String[]{"/bin/sh", "-c", "find "+ logPath + " -maxdepth 1 -type f -exec basename {} \\; | sort"});
            br = new BufferedReader(new InputStreamReader(ps.getInputStream()));

            while( (line = br.readLine()) != null ) {
                fileList.add(line);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { br.close(); } catch(Exception e) {}
        }
%>
<html>
<head>
    <title></title>
    <script src="//code.jquery.com/jquery-1.11.2.min.js"></script>
    <style type="text/css">
        * {
            margin: 0;
            padding: 0;
        }
        #header {
            position: fixed;
            top: 0;
            left: 50px;
            width: 100%;
            height: 10%;
        }
        #console {
            position: fixed;
            bottom: 0;
            width: 100%;
            height: 90%;
            background-color: black;
            color:white;
            font-size: 15px;
        }
        #runningFlag {
            color: red;
        }
    </style>
    <script type="text/javascript">
        var endPoint = 0;
        var tailFlag = false;
        var fileName;
        var consoleLog;
        var grep;
        var grepV;
        var pattern;
        var patternV;
        var runningFlag;
        $(document).ready(function() {
            consoleLog = $('#console');
            runningFlag = $('#runningFlag');

            function startTail() {
                runningFlag.html('Running');
                fileName = $('#fileName').val();
                grep = $.trim($('#grep').val());
                grepV = $.trim($('#grepV').val());
                pattern = new RegExp('.*'+grep+'.*\\n', 'g');
                patternV = new RegExp('.*'+grepV+'.*\\n', 'g');
                function requestLog() {
                    if (tailFlag) {
                        $.ajax({
                            type : 'POST',
                            url : 'tail.jsp',   // #### Caution: The name of the source file
                            dataType : 'json',
                            data : {
                                'log_filename' : fileName,
                                'preEndPoint' : endPoint

                            },
                            success : function(data) {
                                endPoint = data.endPoint == false ? 0 : data.endPoint;
                                logdata = decodeURIComponent(data.log);
                                if (grep != false) {
                                    logdata = logdata.match(pattern).join('');
                                }
                                if (grepV != false) {
                                    logdata = logdata.replace(patternV, '');
                                }
                                consoleLog.val(consoleLog.val() + logdata);
                                consoleLog.scrollTop(consoleLog.prop('scrollHeight'));

                                setTimeout(requestLog, 1000);
                            }
                        });
                    }
                }
                requestLog();
            }
            $('#startTail').on('click', function() {tailFlag = true; startTail();});
            $('#stopTail').on('click', function() {
                tailFlag = false;
                runningFlag.html('Stop');
            });
            $('#fileName').change(function() {
                tailFlag = false;
                endPoint = 0;
                runningFlag.html('Stop');
            });
        });
    </script>
</head>
<body>
<div id="header">
    <h2>Log Tail</h2>
    tail -f
    <select id="fileName">
<%  for (String file : fileList) {  %>
        <option value="<%=file%>"><%=file%></option>
<%  }   %>
    </select>
    | grep <input id="grep" type="text" />
    | grep -v <input id="grepV" type="text" />

    <br/>
    <input id="startTail" type="button" value="startTail" />&nbsp;&nbsp;&nbsp;
    <input id="stopTail" type="button" value="stopTail" />&nbsp;&nbsp;&nbsp;
    <span id="runningFlag">Stop</span><br/>

</div>
<textarea id="console"></textarea>
</body>
</html>
<%
    }
%>
