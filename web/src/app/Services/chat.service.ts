import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject } from 'rxjs';
import { Client, Message } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

@Injectable({
  providedIn: 'root'
})
export class ChatService {
  private apiUrl = 'http://localhost:8085/chat'; // Backend URL
  private stompClient: Client | null = null;
  
  public messageSubject: Subject<any> = new Subject<any>();
  public updateSubject: Subject<any> = new Subject<any>(); // For message updates
  public deleteSubject: Subject<any> = new Subject<any>(); // For message deletions

  constructor(private http: HttpClient) {}

  // Get conversations for the user
  getConversations(userId: string): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/conversations/${userId}`);
  }

  // Get messages for a specific conversation
  getMessages(conversationId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/messages/${conversationId}`);
  }

  // Create a new conversation
  createConversation(user1: number, user2: number): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/conversation/create?user1=${user1}&user2=${user2}`, {});
  }

  // Send a new message
  sendMessage(chatMessage: any) {
    if (this.stompClient && this.stompClient.active) {
      this.stompClient.publish({
        destination: '/app/chat',
        body: JSON.stringify(chatMessage)
      });
    } else {
      console.error("Unable to send message, WebSocket not connected!");
    }
  }

  // Add a reaction to a message
  addReaction(updatedMsg: any): Observable<any> {
    const reactionsJson = JSON.stringify(updatedMsg.reactions);
    return this.http.put(`${this.apiUrl}/messages/${updatedMsg.id}/reactions`, reactionsJson, {
      headers: { 'Content-Type': 'application/json' }
    });
  }
  // Update a message
  updateMessage(messageId: number, newContent: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/messages/${messageId}`, { content: newContent });
  }

  // Delete a message
  deleteMessage(messageId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/messages/${messageId}`);
  }

  // WebSocket connection
  connect(userId: string) {
    if (this.stompClient && this.stompClient.active) {
      return;
    }

    this.stompClient = new Client({
      webSocketFactory: () => new SockJS('http://localhost:8086/ws'),
      debug: (str) => { console.log(str); },
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
    });

    this.stompClient.onConnect = (frame) => {
      console.log('✅ Connected to WebSocket as User: ' + userId);
      
      this.stompClient?.subscribe(`/user/${userId}/queue/messages`, (message: Message) => {
        if (message.body) {
          this.messageSubject.next(JSON.parse(message.body)); // New message
        }
      });

      this.stompClient?.subscribe(`/user/${userId}/queue/updates`, (message: Message) => {
        if (message.body) {
          this.updateSubject.next(JSON.parse(message.body)); // Updated message
        }
      });

      this.stompClient?.subscribe(`/user/${userId}/queue/deletes`, (message: Message) => {
        if (message.body) {
          this.deleteSubject.next(JSON.parse(message.body)); // Deleted message
        }
      });
    };

    this.stompClient.onStompError = (frame) => {
      console.error('❌ WebSocket Error: ' + frame.headers['message']);
    };

    this.stompClient.activate();
  }

  // Disconnect WebSocket
  disconnect() {
    if (this.stompClient) {
      this.stompClient.deactivate();
      console.log('🔌 Disconnected from WebSocket');
    }
  }

  // Upload file (image or PDF)
  uploadFile(formData: FormData): Observable<any> {
    return this.http.post(`${this.apiUrl}/upload`, formData);
  }
}
