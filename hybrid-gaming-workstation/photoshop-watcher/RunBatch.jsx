// RunBatch.jsx
// ExtendScript for Photoshop 2025/27.10
// Expects a JSON-like argument string via $.getenv('PS_BATCH_ARGS') containing:
// {
//   "actionFile": "E:\\CreativeBridge\\photoshop-projects\\...\\Action.atn",
//   "actionSet": "Action Set Name",
//   "actionName": "Action Name",
//   "outputFolder": "E:\\CreativeBridge\\photoshop-projects\\...\\processed",
//   "sourceFiles": [
//     "E:\\CreativeBridge\\photoshop-projects\\...\\images\\IMG_0001.CR2"
//   ],
//   "jpegQuality": 12,
//   "logFile": "E:\\CreativeBridge\\photoshop-projects\\...\\batch.log"
// }

function log(msg) {
    var batchArgs = $.getenv('PS_BATCH_ARGS');
    var args = {};
    try {
        args = JSON.parse(batchArgs);
    } catch (e) {}

    var now = new Date();
    var line = now.toISOString() + ' ' + msg;
    $.writeln(line);

    if (args.logFile) {
        var f = new File(args.logFile);
        f.open('a');
        f.writeln(line);
        f.close();
    }
}

function main() {
    var batchArgs = $.getenv('PS_BATCH_ARGS');
    if (!batchArgs) {
        log('ERROR: PS_BATCH_ARGS environment variable not set');
        return 1;
    }

    var args;
    try {
        args = JSON.parse(batchArgs);
    } catch (e) {
        log('ERROR: Failed to parse PS_BATCH_ARGS: ' + e);
        return 1;
    }

    var actionFile = args.actionFile;
    var actionSet = args.actionSet;
    var actionName = args.actionName;
    var outputFolder = args.outputFolder;
    var sourceFiles = args.sourceFiles || [];
    var jpegQuality = args.jpegQuality || 12;
    var logFile = args.logFile;

    if (!actionFile || !actionSet || !actionName || !outputFolder || sourceFiles.length === 0) {
        log('ERROR: Missing required arguments');
        return 1;
    }

    // Load action set from .atn file
    var actionFileObj = new File(actionFile);
    if (!actionFileObj.exists) {
        log('ERROR: Action file not found: ' + actionFile);
        return 1;
    }

    app.load(actionFileObj);
    log('Loaded action file: ' + actionFile);

    // Ensure output folder exists
    var outFolder = new Folder(outputFolder);
    if (!outFolder.exists) {
        outFolder.create();
    }

    var results = [];

    for (var i = 0; i < sourceFiles.length; i++) {
        var sourcePath = sourceFiles[i];
        var sourceFile = new File(sourcePath);

        if (!sourceFile.exists) {
            log('ERROR: Source file not found: ' + sourcePath);
            results.push({ file: sourcePath, success: false, error: 'File not found' });
            continue;
        }

        try {
            // Open the file
            var doc = app.open(sourceFile);

            // Run the action
            app.doAction(actionName, actionSet);

            // Build output path
            var baseName = doc.name.replace(/\.[^\.]+$/, '');
            var outputPath = outputFolder + '/' + baseName + '.jpg';

            // If output already exists, rename it with a timestamp
            var outputFile = new File(outputPath);
            if (outputFile.exists) {
                var timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                var renamedPath = outputFolder + '/' + baseName + '-' + timestamp + '.jpg';
                outputFile.rename(renamedPath);
                log('Renamed existing output to: ' + renamedPath);
            }

            // Save as JPEG with max quality
            var jpegOptions = new JPEGSaveOptions();
            jpegOptions.quality = jpegQuality;
            jpegOptions.embedColorProfile = true;
            jpegOptions.formatOptions = FormatOptions.STANDARDBASELINE;

            doc.saveAs(outputFile, jpegOptions, true, Extension.LOWERCASE);
            log('Saved: ' + outputPath);

            // Close document without save dialog
            doc.close(SaveOptions.DONOTSAVECHANGES);

            results.push({ file: sourcePath, success: true, output: outputPath });
        } catch (e) {
            log('ERROR processing ' + sourcePath + ': ' + e);
            try {
                if (app.documents.length > 0) {
                    app.activeDocument.close(SaveOptions.DONOTSAVECHANGES);
                }
            } catch (closeErr) {
                log('ERROR closing document after failure: ' + closeErr);
            }
            results.push({ file: sourcePath, success: false, error: e.toString() });
        }
    }

    // Write results summary
    if (logFile) {
        var summary = {
            processed: results.length,
            successful: results.filter(function(r) { return r.success; }).length,
            failed: results.filter(function(r) { return !r.success; }).length,
            results: results
        };
        log('SUMMARY: ' + JSON.stringify(summary));
    }

    // Quit Photoshop to release memory
    log('Quitting Photoshop to release memory');
    app.quit();

    return 0;
}

main();
