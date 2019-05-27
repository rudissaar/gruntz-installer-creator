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

            component.addOperation(
                "Execute",
                "cmd.exe",
                "/C",
                "@TargetDir@/compatibility.bat"
            );
    } else {
        component.addOperation(
            "CreateDesktopEntry",
            "gruntz.desktop",
            "\nEncoding=UTF-8\n" +
            "Name=Gruntz\n" +
            "Type=Application\n" +
            "Comment=The Ultimate Puzzle-Strategy-Action Game\n" +
            "Path=@TargetDir@\n" +
            "Exec=wine32 @TargetDir@/GRUNTZ.EXE\n" +
            "Icon=@TargetDir@/GRUNTZ.ICO\n" +
            "Categories=Game;Emulator;\n" +
            "Terminal=False");
    }
}
