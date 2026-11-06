import { Component, OnInit, OnDestroy, Input, SimpleChanges, OnChanges } from '@angular/core';
import { ChatService } from '../../Services/chat.service'; 
import { UserService } from '../../Services/user.service';
import { ModerationService } from '../../Services/moderation.service';

interface Message {
  id?: number;
  text: string;
  isMe: boolean;
  isEditing?: boolean;
  showMenu?: boolean;
  showReactions?: boolean;
  reactions?: { [emoji: string]: number };
  userReaction?: string;
  imageUrl?: string;
  pdfUrl?: string;
  pdfName?: string;
}

interface ChatUser {
  id: number; 
  otherUserId: number; 
  name: string;
  avatar: string;
  status: string;
  lastMsg: string;
  time: string;
  unread: boolean;
  history: Message[];
}

@Component({
  selector: 'app-messenger',
  templateUrl: './messenger.component.html',
  styleUrls: ['./messenger.component.css']
})
export class MessengerComponent implements OnInit, OnDestroy, OnChanges {
  
  @Input() targetUserId: string = '';

  activeChat: ChatUser | null = null;
  users: ChatUser[] = []; 
  currentUserId: number = 0;
  newMessageText: string = '';
  availableReactions: string[] = ['👍', '❤️', '😂', '😮', '😢', '😠'];
  isHoveringReactionPicker: boolean = false;
  selectedFile: File | null = null;
  filePreviewUrl: string | null = null;
  moderationError: string | null = null;
  isCheckingModeration: boolean = false;

  constructor(
    private chatService: ChatService, 
    private userService: UserService,
    private moderationService: ModerationService
  ) {}

  ngOnInit(): void {
    this.loadUserData();

    if (this.currentUserId > 0) {
      this.chatService.connect(this.currentUserId.toString());

      // 1. Écouter les nouveaux messages
      this.chatService.messageSubject.subscribe((incomingMessage: any) => {
        const chatInList = this.users.find(u => u.id === incomingMessage.conversationId);
        
        if (chatInList) {
          chatInList.lastMsg = this.getPreviewText(incomingMessage.content);
          chatInList.unread = (this.activeChat?.id !== incomingMessage.conversationId);
          chatInList.time = new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        }

        if (this.activeChat && incomingMessage.conversationId === this.activeChat.id) {
          // Évite les doublons si le message a déjà été ajouté localement
          if (!this.activeChat.history.find(m => m.id === incomingMessage.id)) {
            console.log('Received new message:', incomingMessage);
            const parsedMessage = this.parseMessageContent(incomingMessage.content);
            console.log('Parsed message:', parsedMessage);
            
            const newMsg = {
              id: incomingMessage.id,
              text: parsedMessage.text,
              isMe: incomingMessage.senderId === this.currentUserId,
              imageUrl: parsedMessage.imageUrl,
              pdfUrl: parsedMessage.pdfUrl,
              pdfName: parsedMessage.pdfName
            };
            
            console.log('Adding message to history:', newMsg);
            this.activeChat.history.push(newMsg);
            this.scrollToBottom();
          }
        } else if (!chatInList) {
          this.loadConversations();
        }
      });

      // 2. Écouter les mises à jour (Édition)
      this.chatService.updateSubject.subscribe((updatedMsg: any) => {
        if (this.activeChat && updatedMsg.conversationId === this.activeChat.id) {
           const msg = this.activeChat.history.find(m => m.id === updatedMsg.id);
           if (msg) {
             msg.text = updatedMsg.content;
             if (updatedMsg.reactions) {
               try {
                 msg.reactions = JSON.parse(updatedMsg.reactions);
               } catch (e) {
                 console.error('Error parsing reactions update:', e);
                 msg.reactions = {};
               }
             }
           }
        }
      });

      // 3. Écouter les suppressions
      this.chatService.deleteSubject.subscribe((deleteData: any) => {
        if (this.activeChat && deleteData.conversationId === this.activeChat.id) {
           this.activeChat.history = this.activeChat.history.filter(m => m.id !== deleteData.deletedId);
        }
      });

      this.loadConversations();
    }
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['targetUserId'] && this.targetUserId) {
      this.openDirectChat(Number(this.targetUserId));
    }
  }

  ngOnDestroy(): void {
    this.chatService.disconnect();
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
      const payload = token.split('.')[1];
      const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
      this.currentUserId = Number(decodedPayload.id);
    }
  }

  loadConversations() {
    this.chatService.getConversations(this.currentUserId.toString()).subscribe({
      next: (data) => {
        this.users = data.map(conv => {
          const otherId = conv.participant1Id === this.currentUserId ? conv.participant2Id : conv.participant1Id;
          
          const chatUser: ChatUser = {
            id: conv.id,
            otherUserId: otherId,
            name: 'Chargement...', 
            avatar: 'https://placehold.co/40x40/cccccc/ffffff?text=...', 
            status: 'online', 
            lastMsg: 'Cliquez pour voir les messages...',
            time: new Date(conv.lastMessageTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
            unread: false,
            history: []
          };

          this.userService.getUserById(otherId.toString()).subscribe({
            next: (realUser: any) => {
              chatUser.name = `${realUser.firstName || ''} ${realUser.lastName || ''}`.trim() || 'Utilisateur inconnu';
              
              if (realUser.profilePictureUrl) {
                chatUser.avatar = realUser.profilePictureUrl;
              } else {
                chatUser.avatar = `https://ui-avatars.com/api/?name=${realUser.firstName}+${realUser.lastName}&background=random`;
              }

              if (this.targetUserId && Number(this.targetUserId) === chatUser.otherUserId) {
                this.openChat(chatUser);
              }
            },
            error: (err) => console.error(`Erreur chargement utilisateur ${otherId}`, err)
          });

          return chatUser;
        });
      }
    });
  }

  openDirectChat(targetId: number) {
    const existingChat = this.users.find(u => u.otherUserId === targetId);
    if (existingChat) {
      this.openChat(existingChat);
    } else {
      this.loadConversations();
    }
  }

  openChat(user: ChatUser) {
    user.unread = false;
    this.activeChat = user;

    this.chatService.getMessages(user.id).subscribe({
      next: (messagesData) => {
        this.activeChat!.history = messagesData.map(msg => {
          let parsedReactions = {};
          try {
            if (msg.reactions && msg.reactions.trim() !== '') {
              parsedReactions = JSON.parse(msg.reactions);
            }
          } catch (e) {
            console.error('Error parsing reactions:', e);
          }
          
          // Parse file URL from content
          const parsedMessage = this.parseMessageContent(msg.content);
          
          return {
            id: msg.id,
            text: parsedMessage.text,
            isMe: msg.senderId === this.currentUserId,
            reactions: parsedReactions,
            imageUrl: parsedMessage.imageUrl,
            pdfUrl: parsedMessage.pdfUrl,
            pdfName: parsedMessage.pdfName
          };
        });
        this.scrollToBottom();
      }
    });
  }

  parseMessageContent(content: string): { text: string, imageUrl?: string, pdfUrl?: string, pdfName?: string } {
    console.log('Parsing message content:', content);
    
    // Check if content contains file URL - match [FILE:url]
    const fileMatch = content.match(/\[FILE:(https?:\/\/[^\]]+)\]/);
    
    if (fileMatch) {
      const fileUrl = fileMatch[1];
      console.log('Found file URL:', fileUrl);
      
      // Remove the [FILE:url] part and also remove [File: filename] part
      let textPart = content.replace(fileMatch[0], '').trim();
      textPart = textPart.replace(/\[File:\s*[^\]]+\]/i, '').trim();
      
      console.log('Text part:', textPart);
      console.log('File URL:', fileUrl);
      
      // Check if it's an image or PDF
      if (fileUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
        console.log('Detected as image');
        return {
          text: textPart,
          imageUrl: fileUrl
        };
      } else if (fileUrl.match(/\.pdf$/i)) {
        console.log('Detected as PDF');
        const fileName = fileUrl.split('/').pop() || 'Document.pdf';
        return {
          text: textPart,
          pdfUrl: fileUrl,
          pdfName: fileName
        };
      }
    }
    
    console.log('No file detected, returning text only');
    return { text: content };
  }

  getPreviewText(content: string): string {
    const parsed = this.parseMessageContent(content);
    if (parsed.imageUrl) {
      return '📷 Image';
    } else if (parsed.pdfUrl) {
      return '📄 PDF Document';
    }
    return parsed.text || 'Message';
  }

  onImageError(event: any, msg: Message) {
    console.error('Image failed to load:', msg.imageUrl);
    console.error('Error event:', event);
    // Optionally show error message or fallback
    event.target.style.display = 'none';
  }

  downloadPDF(event: Event, pdfUrl: string, pdfName?: string) {
    event.preventDefault();
    console.log('Downloading PDF:', pdfUrl);
    
    // Fetch the PDF and download it
    fetch(pdfUrl)
      .then(response => {
        if (!response.ok) {
          throw new Error('PDF not found (404)');
        }
        return response.blob();
      })
      .then(blob => {
        // Create a download link
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = pdfName || 'document.pdf';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
        console.log('PDF downloaded successfully');
      })
      .catch(error => {
        console.error('Error downloading PDF:', error);
        alert('Failed to download PDF. The file may not be available on the server. Please restart the backend server.');
      });
  }

  downloadImage(event: Event, imageUrl: string) {
    event.preventDefault();
    console.log('Downloading image:', imageUrl);
    
    // Extract filename from URL
    const filename = imageUrl.split('/').pop() || 'image.jpg';
    
    // Fetch the image and download it
    fetch(imageUrl)
      .then(response => {
        if (!response.ok) {
          throw new Error('Image not found (404)');
        }
        return response.blob();
      })
      .then(blob => {
        // Create a download link
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
        console.log('Image downloaded successfully');
      })
      .catch(error => {
        console.error('Error downloading image:', error);
        alert('Failed to download image. The file may not be available on the server. Please restart the backend server.');
      });
  }

  goBack() {
    this.activeChat = null;
    this.targetUserId = ''; 
    this.loadConversations(); 
  }

  sendMessage() {
    if ((!this.newMessageText.trim() && !this.selectedFile) || !this.activeChat) return;

    // Clear previous moderation error
    this.moderationError = null;

    // Check for harmful content before sending
    if (this.newMessageText.trim()) {
      this.isCheckingModeration = true;
      
      this.moderationService.checkMessage(this.newMessageText).subscribe({
        next: (result) => {
          this.isCheckingModeration = false;
          
          if (result.isHarmful) {
            // Block the message
            this.moderationError = result.message || 'This message contains inappropriate content and cannot be sent.';
            console.warn('Message blocked:', result);
            
            // Show error for 5 seconds
            setTimeout(() => {
              this.moderationError = null;
            }, 5000);
            
            return;
          }
          
          // Message is safe, proceed with sending
          this.proceedWithSending();
        },
        error: (err) => {
          console.error('Moderation check failed:', err);
          this.isCheckingModeration = false;
          
          // On API error, use simple local check as fallback
          if (this.moderationService.simpleCheck(this.newMessageText)) {
            this.moderationError = 'This message may contain inappropriate content and cannot be sent.';
            setTimeout(() => {
              this.moderationError = null;
            }, 5000);
            return;
          }
          
          // If both checks pass/fail, allow the message
          this.proceedWithSending();
        }
      });
    } else {
      // No text to check (file only), proceed directly
      this.proceedWithSending();
    }
  }

  private proceedWithSending() {
    if (!this.activeChat) return;

    const chatMessage = {
      conversationId: this.activeChat.id,
      senderId: this.currentUserId,
      recipientId: this.activeChat.otherUserId,
      content: this.newMessageText || (this.selectedFile ? `[File: ${this.selectedFile.name}]` : ''),
      timestamp: new Date()
    };

    // If there's a file, upload it first
    if (this.selectedFile) {
      this.uploadFile(this.selectedFile, chatMessage);
    } else {
      this.chatService.sendMessage(chatMessage);
    }
    
    this.newMessageText = '';
    this.removeFile();
    this.scrollToBottom();
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      console.log('File selected:', file.name, 'Type:', file.type, 'Size:', file.size);
      
      // Check file size (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        alert('File size must be less than 10MB');
        return;
      }

      // Check file type
      const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf'];
      if (!allowedTypes.includes(file.type)) {
        alert('Only images (JPEG, PNG, GIF, WEBP) and PDF files are allowed');
        return;
      }

      this.selectedFile = file;
      console.log('File accepted:', file.name);

      // Create preview for images only
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = (e: any) => {
          this.filePreviewUrl = e.target.result;
          console.log('Image preview created');
        };
        reader.readAsDataURL(file);
      } else {
        console.log('PDF selected, no preview needed');
        this.filePreviewUrl = null;
      }
    }
    
    // Reset the input so the same file can be selected again
    event.target.value = '';
  }

  isImage(file: File): boolean {
    return file.type.startsWith('image/');
  }

  removeFile() {
    this.selectedFile = null;
    this.filePreviewUrl = null;
  }

  uploadFile(file: File, chatMessage: any) {
    console.log('Uploading file:', file.name);
    console.log('Chat message:', chatMessage);
    
    const formData = new FormData();
    formData.append('file', file);
    formData.append('conversationId', chatMessage.conversationId.toString());
    formData.append('senderId', chatMessage.senderId.toString());
    formData.append('recipientId', chatMessage.recipientId.toString());
    formData.append('content', chatMessage.content);

    // Call backend to upload file
    this.chatService.uploadFile(formData).subscribe({
      next: (response: any) => {
        console.log('File uploaded successfully:', response);
        console.log('File URL:', response.fileUrl);
        // The message will be received via WebSocket
      },
      error: (err) => {
        console.error('Error uploading file:', err);
        alert('Failed to upload file. Please try again.');
        // Fallback: send message without file
        this.chatService.sendMessage(chatMessage);
      }
    });
  }


  
  toggleMenu(msg: Message) {
    this.activeChat?.history.forEach(m => { if(m !== msg) m.showMenu = false; });
    msg.showMenu = !msg.showMenu;
  }

  deleteMsg(msg: Message) {
    if (msg.id) {
      this.chatService.deleteMessage(msg.id).subscribe();
    }
  }

  editMsg(msg: Message) {
    msg.isEditing = true;
    msg.showMenu = false;
  }

  saveEdit(msg: Message, newText: string) {
    if (!msg.id || !newText.trim()) {
      msg.isEditing = false;
      return;
    }
    this.chatService.updateMessage(msg.id, newText).subscribe();
    msg.isEditing = false;
  }

  cancelEdit(msg: Message) {
    msg.isEditing = false;
  }

  toggleReactions(msg: Message) {
    console.log('Toggle reactions for message:', msg);
    this.activeChat?.history.forEach(m => { if(m !== msg) m.showReactions = false; });
    msg.showReactions = !msg.showReactions;
    console.log('Show reactions:', msg.showReactions);
  }

  addReaction(msg: Message, emoji: string) {
    console.log('Adding reaction:', emoji, 'to message:', msg);
    if (!msg.id) return;

    if (!msg.reactions) msg.reactions = {};
    
    // Check if user already reacted with this emoji
    if (!msg.userReaction) {
      // First reaction
      msg.reactions[emoji] = (msg.reactions[emoji] || 0) + 1;
      msg.userReaction = emoji;
    } else if (msg.userReaction === emoji) {
      // Remove reaction (clicking same emoji)
      msg.reactions[emoji]--;
      if (msg.reactions[emoji] === 0) delete msg.reactions[emoji];
      msg.userReaction = undefined;
    } else {
      // Change reaction (clicking different emoji)
      msg.reactions[msg.userReaction]--;
      if (msg.reactions[msg.userReaction] === 0) delete msg.reactions[msg.userReaction];
      msg.reactions[emoji] = (msg.reactions[emoji] || 0) + 1;
      msg.userReaction = emoji;
    }

    msg.showReactions = false;
    console.log('Updated reactions:', msg.reactions);

    // Send to backend
    const updatedMsg = {
      id: msg.id,
      reactions: msg.reactions
    };
    
    this.chatService.addReaction(updatedMsg).subscribe({
      next: (response) => {
        console.log('Reaction saved successfully:', response);
      },
      error: (err) => {
        console.error('Error saving reaction:', err);
        // Revert on error
        if (msg.userReaction === emoji) {
          msg.reactions![emoji]--;
          if (msg.reactions![emoji] === 0) delete msg.reactions![emoji];
          msg.userReaction = undefined;
        }
      }
    });
  }

  getReactionsList(reactions: { [emoji: string]: number } | undefined): string[] {
    if (!reactions) return [];
    return Object.keys(reactions).filter(emoji => reactions[emoji] > 0);
  }

  onMessageRowLeave(msg: Message) {
    setTimeout(() => {
      if (!this.isHoveringReactionPicker) {
        msg.showMenu = false;
        msg.showReactions = false;
      }
    }, 100);
  }

  onReactionPickerEnter() {
    this.isHoveringReactionPicker = true;
  }

  onReactionPickerLeave() {
    this.isHoveringReactionPicker = false;
  }

  scrollToBottom() {
    setTimeout(() => {
      const chatBody = document.querySelector('.chat-body');
      if (chatBody) {
        chatBody.scrollTop = chatBody.scrollHeight;
      }
    }, 100);
  }
}