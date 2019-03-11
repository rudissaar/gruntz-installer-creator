function Component()
{

}

Component.prototype.createOperations = function()
{
    component.createOperations();

    if (systemInfo.productType === "windows") {
        component.addOperation(
            "CreateShortcut",
            "@TargetDir@/GRUNTZ.EXE",
            "@StartMenuDir@/Gruntz.lnk",
            "workingDirectory=@TargetDir@",
            "iconPath=@TargetDir@/GRUNTZ.ICO",
            "description=The Ultimate Puzzle-Strategy-Action Game");
    }
}
