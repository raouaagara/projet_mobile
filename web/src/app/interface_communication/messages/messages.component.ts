import { Component, forwardRef, Inject, OnDestroy, OnInit } from '@angular/core';
import { ChatService } from '../../Services/chat.service';
import { Router } from '@angular/router';



@Component({
  selector: 'app-messages',
  templateUrl: './messages.component.html',
  styleUrl: './messages.component.css'
})
export class MessagesComponent implements OnInit, OnDestroy {
  currentUserId: number = 0;
  conversations: any[] = [];
  selectedConversation: any = null;
  messages: any[] = [];
  newMessageText: string = '';

constructor(
    @Inject(forwardRef(() => ChatService)) private chatService: ChatService, // 2. Use Inject + forwardRef
    private router: Router
  ) {}  

  ngOnInit(): void {
    // 1. Récupérer l'ID de l'utilisateur connecté
    this.loadUserData();

    if (this.currentUserId > 0) {
      // 2. Se connecter au "téléphone" WebSocket
      this.chatService.connect(this.currentUserId.toString());

      // 3. Écouter la sonnerie (les nouveaux messages qui arrivent en direct)
      this.chatService.messageSubject.subscribe((incomingMessage: any) => {
        // Si le message appartient à la conversation ouverte, on l'affiche tout de suite !
        if (this.selectedConversation && incomingMessage.conversationId === this.selectedConversation.id) {
          this.messages.push(incomingMessage);
          this.scrollToBottom();
        }
      });

      // 4. Charger la liste des contacts (conversations)
      this.loadConversations();
    }
  }

  ngOnDestroy(): void {
    // Quand on quitte la page de messages, on raccroche le téléphone
    this.chatService.disconnect();
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (!storedData) {
      this.router.navigate(['/login']);
      return;
    }
    try {
      let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
      const payload = token.split('.')[1];
      const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
      this.currentUserId = Number(decodedPayload.id);
    } catch (e) {
      this.router.navigate(['/login']);
    }
  }

  loadConversations() {
    this.chatService.getConversations(this.currentUserId.toString()).subscribe({
      next: (data) => {
        this.conversations = data;
      },
      error: (err) => console.error("Erreur chargement conversations", err)
    });
  }

  selectConversation(conv: any) {
    this.selectedConversation = conv;
    // Quand on clique sur un contact, on charge l'historique de la discussion
    this.chatService.getMessages(conv.id).subscribe({
      next: (data) => {
        this.messages = data;
        this.scrollToBottom();
      },
      error: (err) => console.error("Erreur chargement messages", err)
    });
  }

  sendMessage() {
    if (!this.newMessageText.trim() || !this.selectedConversation) return;

    // Déterminer qui est l'autre personne dans la conversation
    const recipientId = this.selectedConversation.participant1Id === this.currentUserId 
                        ? this.selectedConversation.participant2Id 
                        : this.selectedConversation.participant1Id;

    const chatMessage = {
      conversationId: this.selectedConversation.id,
      senderId: this.currentUserId,
      recipientId: recipientId,
      content: this.newMessageText,
      timestamp: new Date()
    };

    // 1. Envoyer au backend via WebSocket
    this.chatService.sendMessage(chatMessage);

    // 2. Afficher mon propre message sur mon écran
    this.messages.push(chatMessage);
    this.newMessageText = ''; // Vider le champ de texte
    this.scrollToBottom();
  }

  // Petite astuce pour toujours descendre en bas du chat quand un message arrive
  scrollToBottom() {
    setTimeout(() => {
      const chatBox = document.getElementById('chat-history');
      if (chatBox) {
        chatBox.scrollTop = chatBox.scrollHeight;
      }
    }, 100);
  }

  // Permet de savoir quel est l'ID de l'autre personne (pour afficher un faux nom en attendant)
  getOtherParticipantId(conv: any): number {
    return conv.participant1Id === this.currentUserId ? conv.participant2Id : conv.participant1Id;
  }
}
