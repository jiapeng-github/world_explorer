import AppKit
// Authored teaching cards, explicitly distinguished from documentary images.
let root=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
let cards:[(Int,String,[String],String)]=[
(24,"市场里的标签",["① 名称：苹果","② 单位：千克","③ 产地：法国"],"原创练习 · 不代表照片中商品的真实信息"),
(30,"同一座城市 · 不同语言名称",["Strasbourg   法语","Straßburg   德语","斯特拉斯堡   中文"],"原创名称卡 · 德语不等于阿尔萨斯语"),
(36,"从规定到参与",["1944   法规确立选举权","1945   女性参与相关选举"],"原创时间关系示意 · 不按时间比例")]
for (n,title,lines,footer) in cards{
 let img=NSImage(size:NSSize(width:960,height:600));img.lockFocus()
 NSColor(calibratedRed:0.95,green:0.97,blue:0.99,alpha:1).setFill();NSRect(x:0,y:0,width:960,height:600).fill()
 func text(_ s:String,_ y:Double,_ size:Double,_ bold:Bool=false){(s as NSString).draw(at:NSPoint(x:55,y:y),withAttributes:[.font:bold ? NSFont.boldSystemFont(ofSize:size):NSFont.systemFont(ofSize:size),.foregroundColor:NSColor(calibratedRed:0.07,green:0.22,blue:0.35,alpha:1)])}
 text(title,510,36,true)
 for (i,line) in lines.enumerated(){NSColor.white.setFill();NSBezierPath(roundedRect:NSRect(x:35,y:Double(365-i*110),width:890,height:90),xRadius:18,yRadius:18).fill();text(line,Double(386-i*110),38,true)}
 text(footer,35,22)
 img.unlockFocus();let rep=NSBitmapImageRep(data:img.tiffRepresentation!)!;try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:root+String(format:"/assets/atlas/fra-m%02d.png",n)))
}
