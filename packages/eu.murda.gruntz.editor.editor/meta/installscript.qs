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
            "iconPath=@TargetDir@/GruntzEdit.ico",
            "description=Gruntz Level Editor");
    } else {
        component.addOperation(
            "CreateDesktopEntry",
            "gruntz-editor.desktop",
            "\nEncoding=UTF-8\n" +
            "Name=Gruntz Level Editor\n" +
            "Type=Application\n" +
            "Comment=Gruntz Level Editor\n" +
            "Path=@TargetDir@\n" +
            "Exec=wine32 @TargetDir@/GruntzEdit.exe\n" +
            "Icon=@TargetDir@/GruntzEdit.ico\n" +
            "Categories=Game;Emulator;\n" +
            "Terminal=False");
    }
}
