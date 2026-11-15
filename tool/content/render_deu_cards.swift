import AppKit
let root=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
let cards:[(Int,String,[String],String)]=[
(17,"年代需要史料支持",["新天鹅堡","1869 年 9 月 5 日 · 奠基","来源：巴伐利亚宫殿管理局"],"原创资料摘记 · 不是历史文件原件"),
(30,"市场里的标签",["① 名称：苹果","② 单位：千克","③ 产地：德国"],"原创虚构练习 · 非照片中商品的真实标签"),
(31,"同一座城市 · 不同语言名称",["Berlin   德语","柏林   中文"],"原创名称卡 · 不是现场路牌"),
(32,"一起回应四拍",["1      2      3      4","每一拍之间，间隔相同"],"原创节拍卡 · 跟随阅读页的圆点练习"),
(36,"怎样查考一份历史资料",["谁制作或保存？","形成于什么时间？","来自哪一份记录？"],"原创资料类型教学卡 · 不是档案原件")]
for (n,title,lines,footer) in cards{
 let img=NSImage(size:NSSize(width:960,height:600));img.lockFocus()
 NSColor(calibratedRed:0.95,green:0.97,blue:0.99,alpha:1).setFill();NSRect(x:0,y:0,width:960,height:600).fill()
 func text(_ s:String,_ y:Double,_ size:Double,_ bold:Bool=false){(s as NSString).draw(at:NSPoint(x:55,y:y),withAttributes:[.font:bold ? NSFont.boldSystemFont(ofSize:size):NSFont.systemFont(ofSize:size),.foregroundColor:NSColor(calibratedRed:0.07,green:0.22,blue:0.35,alpha:1)])}
 text(title,510,36,true)
 for (i,line) in lines.enumerated(){NSColor.white.setFill();NSBezierPath(roundedRect:NSRect(x:35,y:Double(365-i*110),width:890,height:90),xRadius:18,yRadius:18).fill();text(line,Double(386-i*110),34,true)}
 text(footer,35,22)
 img.unlockFocus();let rep=NSBitmapImageRep(data:img.tiffRepresentation!)!;try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:root+String(format:"/assets/atlas/deu-m%02d.png",n)))
}
