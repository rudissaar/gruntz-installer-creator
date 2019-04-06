function Component()
{

}

Component.prototype.createOperations = function()
{
    component.createOperations();

    if (systemInfo.productType === "windows") {
        component.addOperation(
            "CreateShortcut",
            "@TargetDir@/GruntzEdit.exe",
            "@StartMenuDir@/Gruntz Level Editor.lnk",
            "workingDirectory=@TargetDir@",
            "iconPath=@TargetDir@/GruntzEdit.exe",
            "description=Gruntz Level Editor");
    }
}
