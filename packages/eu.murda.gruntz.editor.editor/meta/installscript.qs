function Component()
{

}

Component.prototype.createOperations = function()
{
    component.createOperations();

    if (systemInfo.productType === "windows") {
        component.addOperation(
            "CreateShortcut",
            "@TargetDir@/gruntz-editor.exe",
            "@StartMenuDir@/Gruntz Level Editor.lnk",
            "workingDirectory=@TargetDir@",
            "iconPath=@TargetDir@/gruntz-editor.exe",
            "description=Gruntz Level Editor");
    }
}
