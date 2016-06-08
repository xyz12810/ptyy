// Copyright 2016 <chaishushan{AT}gmail.com>. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

class MainViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var navigationBar: UINavigationBar!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var tableView: UITableView!
	
	var refreshControl = UIRefreshControl()

	var db:DataEngin = DataEngin()
	var results = [[String]]()

    override func viewDidLoad() {
        super.viewDidLoad()

		self.searchBar.delegate = self

		let footerBar = UILabel()
		footerBar.text = "共 N 个结果\n"
		footerBar.textAlignment = NSTextAlignment.Center
		footerBar.numberOfLines = 0
		footerBar.lineBreakMode = NSLineBreakMode.ByWordWrapping
		footerBar.textColor = UIColor.darkGrayColor()
		footerBar.sizeToFit()

		self.tableView.tableFooterView = footerBar
		self.tableView.dataSource = self
		self.tableView.delegate = self
		
		self.refreshControl.addTarget(self, action: #selector(MainViewController.refreshData), forControlEvents: UIControlEvents.ValueChanged)
		self.tableView.addSubview(self.refreshControl)

		// 注册TableViewCell
		self.tableView.registerClass(MyCustomMenuCell.self, forCellReuseIdentifier: MyCustomMenuCell.ReuseIdentifier)

		// 生成初始列表
		self.searchBarSearchButtonClicked(searchBar)
    }

	// 刷新数据
	func refreshData() {
		NSThread.sleepForTimeInterval(1.0)
		self.refreshControl.endRefreshing()
	}
	
	// 分享App
	@IBAction func onShareApp(sender: UIBarButtonItem) {
		let utlTilte = "野鸡医院 - 莆田系医院查询"
		let urlStr = "https://appsto.re/cn/QH8ocb.i"
		let appStoreUrl = NSURL(string: urlStr.stringByAddingPercentEncodingWithAllowedCharacters(
			NSCharacterSet.URLQueryAllowedCharacterSet())!)

		let activity = UIActivityViewController(activityItems: [utlTilte, appStoreUrl!], applicationActivities: nil)
		self.presentViewController(activity, animated: true, completion: nil)

		// 修复 iPad 上崩溃问题
		if #available(iOS 8.0, *) {
    		let presentationController = activity.popoverPresentationController
    		presentationController?.sourceView = view
		}
	}

	// 关于按钮
	@IBAction func onAbout(sender: UIBarButtonItem) {
		let title = "关于 野鸡医院"
		let message = "" +
		"用于查询中国大陆较常见的非公有或私人承包的野鸡医院或科室(以莆田系为主)，支持 拼音/汉字/数字/正则 查询。\n" +
		"\n" +
		"查询数据来源于互联网, 本应用并不保证数据的真实性和准确性，查询结果只作为就医前的一个参考。\n" +
		"\n" +
		"版权 2016 @chaishushan"

		if #available(iOS 8.0, *) {
			let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)

			let githubAction = UIAlertAction(title: "Github", style: UIAlertActionStyle.Default) { (result : UIAlertAction) -> Void in
				let urlStr = "https://github.com/chai2010/ptyy"
				let githubUrl = NSURL(string: urlStr.stringByAddingPercentEncodingWithAllowedCharacters(
					NSCharacterSet.URLQueryAllowedCharacterSet())!)
				UIApplication.sharedApplication().openURL(githubUrl!)
			}
			let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Default) { (result : UIAlertAction) -> Void in
				// OK
			}

			alertController.addAction(githubAction)
			alertController.addAction(cancelAction)

			self.presentViewController(alertController, animated: true, completion: nil)
		} else {
			let alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "确定")
			alert.show()
		}
	}

	// -------------------------------------------------------
	// UITableViewDataSource
	// -------------------------------------------------------

	// 表格单元数目
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self.results.count
	}
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.results[section].count
	}

	// 表格单元
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCellWithIdentifier(MyCustomMenuCell.ReuseIdentifier, forIndexPath: indexPath)
		cell.textLabel?.text = self.results[indexPath.section][indexPath.row]
		return cell
	}

	// 右侧索引
	func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
		var keys:[String] = []
		for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ#".characters {
			keys.append("\(ch)")
		}
		return keys
	}

	// -------------------------------------------------------
	// UITableViewDelegate
	// -------------------------------------------------------

	func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

	func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
		return action == MenuAction.Copy.selector() || MenuAction.supportedAction(action)
	}

	func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
		if action == #selector(NSObject.copy(_:)) {
			let cell = tableView.cellForRowAtIndexPath(indexPath)
			UIPasteboard.generalPasteboard().string = cell!.textLabel!.text
		}
	}

	// 选择列时隐藏搜索键盘
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.searchBar.showsCancelButton = false

		// 更新检索栏状态
		self.searchBar.resignFirstResponder()

		// 已经选择的话, 则取消选择
		if indexPath == tableView.indexPathForSelectedRow {
			self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		}
	}

	// -------------------------------------------------------
	// UISearchBarDelegate
	// -------------------------------------------------------

	// 检索栏状态
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		self.searchBar.showsCancelButton = true
	}

	// 点击搜索按钮
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		// 根据查询条件查询结果
		self.results = self.db.SearchV2(searchBar.text!)
		self.searchBar.showsCancelButton = false

		let footerBar = self.tableView.tableFooterView as? UILabel
		footerBar!.text = "共 \(self.numberOfResult()) 个结果\n"

		// 更新列表视图
		self.tableView.reloadData()

		self.searchBar.resignFirstResponder()
	}


	// 检索词发生变化
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		// 根据查询条件查询结果
		self.results = self.db.SearchV2(searchBar.text!)

		let footerBar = self.tableView.tableFooterView as? UILabel
		footerBar!.text = "共 \(self.numberOfResult()) 个结果\n"

		// 更新列表视图
		self.tableView.reloadData()
	}

	// 取消搜索
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		// 隐藏取消按钮
		self.searchBar.showsCancelButton = false
		self.searchBar.text = ""

		// 根据查询条件查询结果(没有查询条件)
		self.results = self.db.SearchV2("")

		let footerBar = self.tableView.tableFooterView as? UILabel
		footerBar!.text = "共 \(self.numberOfResult()) 个结果\n"

		// 更新列表视图
		self.tableView.reloadData()

		// 更新检索栏状态
		self.searchBar.resignFirstResponder()
	}

	// -------------------------------------------------------
	// 辅助函数
	// -------------------------------------------------------

	// 结果总数
	private func numberOfResult() -> Int {
		var sum:Int = 0
		for x in self.results {
			sum += x.count
		}
		return sum
	}

	// -------------------------------------------------------
	// END
	// -------------------------------------------------------
}
