import AppKit
let cards = [
 ("study", "AUSTRALIA · FIELD NOTES", "阅读人与土地的故事", "从公开资料出发 · 尊重讲述者", "名称  /  作者  /  年代  /  来源"),
 ("history-before", "LONG HISTORIES", "历史，不从殖民开始", "多样的社区 · 延续至今的文化", "过去的线索，与今天的声音相连"),
 ("history-colonial", "1788 · COLONISATION", "土地与生活的改变", "理解影响，也听见当地人的行动", "读记录 · 认清作者 · 比较视角"),
 ("history-federal", "1901 · FEDERATION", "六个殖民地，组成联邦", "制度形成，与平等参与并非同一件事", "国家与州 · 不同层级的公共事务"),
 ("food-label", "READ A LABEL", "名称：苹果", "单位：千克     产地：澳大利亚", "原创教学标签 · 不对应照片中的商品")
]
for (slug,kicker,title,sub,detail) in cards {
 let image=NSImage(size:NSSize(width:1200,height:750)); image.lockFocus()
 NSColor(calibratedRed:0.94,green:0.96,blue:0.98,alpha:1).setFill(); NSRect(x:0,y:0,width:1200,height:750).fill()
 NSColor(calibratedRed:0.07,green:0.22,blue:0.36,alpha:1).setFill(); NSBezierPath(roundedRect:NSRect(x:75,y:100,width:1050,height:550),xRadius:28,yRadius:28).fill()
 NSColor(calibratedRed:1,green:0.60,blue:0.24,alpha:1).setFill(); NSRect(x:115,y:560,width:68,height:9).fill()
 func text(_ value:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ color:NSColor) {
  (value as NSString).draw(at:NSPoint(x:x,y:y),withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:.semibold),.foregroundColor:color])
 }
 text(kicker,115,510,24,NSColor(calibratedRed:1,green:0.7,blue:0.4,alpha:1))
 text(title,115,365,48,.white); text(sub,115,280,30,.white);text(detail,115,170,24,NSColor(white:0.78,alpha:1))
 text("世界大百科 · 原创学习卡（非历史影像）",80,42,20,NSColor(white:0.4,alpha:1))
 image.unlockFocus();let rep=NSBitmapImageRep(data:image.tiffRepresentation!)!
 try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"assets/atlas/aus-\(slug).png"))
}
