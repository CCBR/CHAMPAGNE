class Utils {
    // run spooker for the workflow
    public static String spooker(workflow) {
        def pipeline_name = "${workflow.manifest.name.tokenize('/')[-1]}"
        def out = new StringBuilder()
        def err = new StringBuilder()
        def spooker_in_path = check_command_in_path("spooker")
        if (spooker_in_path) {
            try {
                println "Running spooker"
                def spooker_command = "spooker --outdir ${workflow.launchDir} --name ${pipeline_name} --version ${workflow.manifest.version} --path ${workflow.projectDir}"
                def command = spooker_command.execute()
                command.consumeProcessOutput(out, err)
                command.waitFor()
            } catch(IOException e) {
                err = e
            }
            new FileWriter("${workflow.launchDir}/log/spooker.log").with {
                write("${out}\n${err}")
                flush()
            }
        } else {
            err = "spooker not found, skipping"
        }
        return err
    }
    // check whether a command is in the path
    public static Boolean check_command_in_path(cmd) {
        def out = new StringBuilder()
        def err = new StringBuilder()
        try {
            // `command` is a shell builtin, so it must run via a shell rather than
            // String.execute() (which uses Runtime.exec and would throw IOException).
            def command = ["bash", "-c", "command -v ${cmd}"].execute()
            command.consumeProcessOutput(out, err)
            command.waitFor()
            return command.exitValue() == 0
        } catch(Exception e) {
            return false
        }
    }
}
