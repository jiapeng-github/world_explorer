import AppKit
let root=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
let cards:[(Int,String,[String],String)]=[
(28,"市场里的标签",["① 名称：玉米粉","② 单位：千克","③ 产地：肯尼亚"],"原创虚构练习 · 非照片中商品的真实标签"),
(29,"同一座城市 · 不同语言名称",["Nairobi","内罗毕","两个名称，指同一座城市"],"原创名称卡 · 不是现场路牌"),
(31,"一起回应四拍",["1      2      3      4","每一拍之间，间隔相同"],"原创节拍练习 · 不是Isukuti传统音乐转录"),
(33,"怎样追溯博物馆里的材料",["名称：这件材料叫什么？","年代：记录了哪个时期？","资料来源：根据哪份记录？"],"原创字段示意 · 不是馆藏文物或真实说明牌"),
(34,"认识肯尼亚独立的日期",["1963 年 12 月 12 日 · 独立","1964 年 12 月 12 日 · 成为共和国","来源：肯尼亚政府纪念日资料"],"原创事实摘记 · 不是历史档案原件"),
(35,"宪法与公共生活",["2010 年 · 肯尼亚宪法","基本制度与重要权利","来源：Kenya Law 宪法文本"],"原创事实摘记 · 不是法律文件原件"),
(36,"红茶加工 · 认识几个阶段",["萎凋 → 揉捻或切碎","氧化 → 干燥","来源：华盛顿州立大学茶叶加工资料"],"原创流程卡 · 不同工艺的具体做法有差异")]
for (n,title,lines,footer) in cards{
 let img=NSImage(size:NSSize(width:960,height:600));img.lockFocus()
 NSColor(calibratedRed:0.95,green:0.97,blue:0.99,alpha:1).setFill();NSRect(x:0,y:0,width:960,height:600).fill()
 func text(_ s:String,_ y:Double,_ size:Double,_ bold:Bool=false){(s as NSString).draw(at:NSPoint(x:55,y:y),withAttributes:[.font:bold ? NSFont.boldSystemFont(ofSize:size):NSFont.systemFont(ofSize:size),.foregroundColor:NSColor(calibratedRed:0.07,green:0.22,blue:0.35,alpha:1)])}
 text(title,510,36,true)
 for (i,line) in lines.enumerated(){NSColor.white.setFill();NSBezierPath(roundedRect:NSRect(x:35,y:Double(365-i*110),width:890,height:90),xRadius:18,yRadius:18).fill();text(line,Double(386-i*110),30,true)}
 text(footer,35,22)
 img.unlockFocus();let rep=NSBitmapImageRep(data:img.tiffRepresentation!)!;try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:root+String(format:"/assets/atlas/kenya-m%02d.png",n)))
}
