//
//  TimelineDetailCommentViewController.swift
//  Mosaiek
//
//  Created by Jonathan Schapiro on 1/31/16.
//  Copyright © 2016 Jonathan Schapiro. All rights reserved.
//

import UIKit

class TimelineDetailCommentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var mosaicImage:PFObject?
    
    @IBOutlet weak var mosaicImageView: UIImageView!
    
    @IBOutlet weak var mosaicImageComments: UITableView!
    
    @IBOutlet weak var mosaicImageUserPic: UIImageView!
    
    @IBOutlet weak var mosaicImageLikes: UILabel!
    
    @IBOutlet weak var commentField: UITextField!
    
    @IBOutlet weak var mosaicImageLikeButton: UIButton!
    
    var comments:[PFObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mosaicImageComments.delegate = self;
        self.mosaicImageComments.dataSource = self;
        
        self.commentField.delegate = self;
        
        self.setupView();
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        
        if let mosaicImg = self.mosaicImage {
            
            if let image = mosaicImg["image"] as? PFFile {
                
                MosaicImage.fileToImage(image, completion: { (mosaicImage) -> Void in
                    
                    if let viewImage = mosaicImage {
                        
                        self.mosaicImageView.image = viewImage;
                        
                    }
                })
            }
            
            if let likes = mosaicImg["likes"] as? Int {
                
                self.mosaicImageLikes?.text = String(likes);
                
            }
            
            if let mosaicImageUser = mosaicImg["user"] {
                
                if let profilePic = mosaicImageUser["profilePic"] as? String {
                    
                    if let url = NSURL(string: profilePic) {
                        
                        if let data = NSData(contentsOfURL: url) {
                            
                            mosaicImageUserPic.image = UIImage(data: data)
                            
                        }
                    }

                }
            }
            
            self.mosaicImageLikeButton.enabled = false;
            MosaicImage.mosaicImageIsLiked(mosaicImg, completion: { (liked, likeRelationship) -> Void in
                if (liked == true) {
                    self.mosaicImageLikeButton.setBackgroundImage(UIImage(named: "likes_filled"), forState: UIControlState.Normal);
                    
                } else {
                    self.mosaicImageLikeButton.setBackgroundImage(UIImage(named: "likes"), forState: UIControlState.Normal);
                }
                
                self.mosaicImageLikeButton.enabled = true;
            })
        }
        
        // view populated - now get comments
        if let mosaicImg = self.mosaicImage {
            Comment.getUserComments(mosaicImg, completion: { (comments) -> Void in
                
                if let imageComments = comments {
                    
                    self.comments = imageComments;
                    
                    self.mosaicImageComments.reloadData()
                }
            })
        }
        
    }
    
    
    // #MARK - IBAction
    
    @IBAction func writeComment(sender: AnyObject) {
        
        print("write comment");
        self.commentField?.hidden = false;
        
    }
   
    @IBAction func likeMosaicImage(sender: AnyObject) {
        
        
        if (self.mosaicImageLikeButton.backgroundImageForState(UIControlState.Normal) == UIImage(named: "likes")) {
           
            
            self.mosaicImageLikeButton.setBackgroundImage(UIImage(named: "likes_filled"), forState: UIControlState.Normal);
            
            self.mosaicImageLikes.text = String(Int(self.mosaicImageLikes.text!)! + 1);
           
            if let mImage = self.mosaicImage {
                
                MosaicImage.likeMosaicImage(mImage);
            }
            
        } else if (self.mosaicImageLikeButton.backgroundImageForState(UIControlState.Normal) == UIImage(named: "likes_filled")){
           
            
            self.mosaicImageLikeButton.setBackgroundImage(UIImage(named: "likes"), forState: UIControlState.Normal);
            
            self.mosaicImageLikes.text = String(Int(self.mosaicImageLikes.text!)! - 1);
            
            if let mImage = self.mosaicImage {
                
                MosaicImage.removeMosaicImageLike(mImage);
                
            }

        } else {
            
            return;
        }
        
    }
    // #MARK - TableView Delegate Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1;
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let dataSource = self.comments {
            
            return dataSource.count;
        }
        
        
        return 0;
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:CommentCell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath) as! CommentCell
        
        if let user = self.comments![indexPath.row]["user"] {
           
            
            if let userCommentImage = user["profilePic"] as? String {
                
                if let url = NSURL(string: userCommentImage) {
                    
                    if let data = NSData(contentsOfURL: url) {
                        
                        cell.commentUserImage.image = UIImage(data: data)
                        
                    }
                }

            }
        }
        
        if let comment = self.comments![indexPath.row]["comment"] as? String {
            
            cell.commentText?.text = comment;
        } else {
            cell.commentText?.text = "Be the first to comment!";
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
        
    }
    
    // #MARK - Text Field Delegate Methods
    func textFieldDidBeginEditing(textField: UITextField) {
        print("began editing");
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        print("should end editing");
        return true
    }
   
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let comment = self.commentField?.text {
            
            if let mosaicImg = self.mosaicImage {
                
                Comment.saveComment(mosaicImg, comment: comment, completion: { (success,commentObject) -> Void in
                    self.comments?.insert(commentObject, atIndex: 0);
                    self.mosaicImageComments.reloadData();
                    print("comment saved", success);
                })
            
            }
            
        }
        
        self.commentField.text = "";
        return true
    }
    
    //#MARK - Segue
   
    
    
}
