import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { AiCvService, CVAnalysisRequest, CVAnalysisResponse } from '../../services-ayoub/ai-cv.service';
import { SubscriptionService } from '../../services-ayoub/subscription.service';

@Component({
  selector: 'app-ai-cv-generator',
  templateUrl: './ai-cv-generator.component.html',
  styleUrl: './ai-cv-generator.component.css'
})
export class AiCvGeneratorComponent implements OnInit, OnDestroy {
  currentUserId = 1;
  
  // Access control
  hasAccess = false;
  loading = true;
  checkingAccess = true;
  
  // Form data
  cvText = '';
  targetDomain = '';
  jobDomains: string[] = [];
  uploadedFileName = '';
  
  // Analysis state
  analyzing = false;
  analysisComplete = false;
  analysisResult: CVAnalysisResponse | null = null;
  errorMessage = '';
  
  // UI state
  activeTab: 'input' | 'result' = 'input';
  showCopySuccess = false;
  showDownloadOptions = false;
  downloadFormat: 'pdf' | 'docx' | 'txt' = 'pdf';

  // Helper method to check if uploaded file is an image
  get isUploadedFileImage(): boolean {
    if (!this.uploadedFileName) return false;
    return /\.(png|jpg|jpeg|webp)$/i.test(this.uploadedFileName);
  }

  constructor(
    private aiCvService: AiCvService,
    private subscriptionService: SubscriptionService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.checkAccess();
    this.jobDomains = this.aiCvService.getJobDomains();
    
    // Close dropdown when clicking outside
    document.addEventListener('click', this.closeDownloadOptions.bind(this));
  }

  ngOnDestroy(): void {
    document.removeEventListener('click', this.closeDownloadOptions.bind(this));
  }

  closeDownloadOptions(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    if (!target.closest('.download-dropdown')) {
      this.showDownloadOptions = false;
    }
  }

  checkAccess(): void {
    this.checkingAccess = true;
    this.subscriptionService.getActiveSubscription(this.currentUserId).subscribe({
      next: (sub) => {
        if (sub && sub.status === 'ACTIVE') {
          const planType = sub.plan?.type?.toUpperCase();
          this.hasAccess = planType === 'PREMIUM' || planType === 'ENTERPRISE';
        } else {
          this.hasAccess = false;
        }
        this.checkingAccess = false;
        this.loading = false;
      },
      error: () => {
        this.hasAccess = false;
        this.checkingAccess = false;
        this.loading = false;
      }
    });
  }

  onFileSelected(event: any): void {
    const file: File = event.target.files[0];
    if (!file) return;

    this.uploadedFileName = file.name;
    this.errorMessage = '';

    
    if (this.aiCvService.isImageFile(file)) {
      
      this.cvText = '[IMAGE_UPLOADED]'; 
    } else {
    
      this.aiCvService.extractTextFromFile(file).then(
        text => {
          this.cvText = text;
        },
        error => {
          this.errorMessage = error.message;
          this.uploadedFileName = '';
        }
      );
    }
  }

  removeFile(): void {
    this.uploadedFileName = '';
    this.cvText = '';
    const fileInput = document.getElementById('cvFileInput') as HTMLInputElement;
    if (fileInput) fileInput.value = '';
  }

  analyzeCV(): void {
    // Validation
    if (!this.cvText || this.cvText.trim().length < 10) {
      this.errorMessage = 'Please provide a CV (text or image)';
      return;
    }

    if (!this.targetDomain) {
      this.errorMessage = 'Please select a target job domain';
      return;
    }

    this.errorMessage = '';
    this.analyzing = true;
    this.analysisComplete = false;

    // Check if user uploaded an image
    const fileInput = document.getElementById('cvFileInput') as HTMLInputElement;
    const file = fileInput?.files?.[0];

    if (file && this.aiCvService.isImageFile(file)) {
      // Process image with Vision API
      this.aiCvService.convertImageToBase64(file).then(
        ({ base64, mimeType }) => {
          this.aiCvService.analyzeAndImproveCVFromImage(base64, mimeType, this.targetDomain).subscribe({
            next: (result) => {
              this.analysisResult = result;
              this.analysisComplete = true;
              this.analyzing = false;
              this.activeTab = 'result';
            },
            error: (error) => {
              this.errorMessage = error.message || 'Failed to analyze CV image. Please try again.';
              this.analyzing = false;
            }
          });
        },
        error => {
          this.errorMessage = error.message;
          this.analyzing = false;
        }
      );
    } else {
      // Process text with regular API
      const request: CVAnalysisRequest = {
        cvText: this.cvText,
        targetDomain: this.targetDomain
      };

      this.aiCvService.analyzeAndImproveCV(request).subscribe({
        next: (result) => {
          this.analysisResult = result;
          this.analysisComplete = true;
          this.analyzing = false;
          this.activeTab = 'result';
        },
        error: (error) => {
          this.errorMessage = error.message || 'Failed to analyze CV. Please try again.';
          this.analyzing = false;
        }
      });
    }
  }

  copyToClipboard(text: string): void {
    navigator.clipboard.writeText(text).then(() => {
      this.showCopySuccess = true;
      setTimeout(() => {
        this.showCopySuccess = false;
      }, 2000);
    });
  }

  toggleDownloadOptions(): void {
    this.showDownloadOptions = !this.showDownloadOptions;
  }

  selectDownloadFormat(format: 'pdf' | 'docx' | 'txt'): void {
    this.downloadFormat = format;
    this.downloadImprovedCV();
    this.showDownloadOptions = false;
  }

  downloadImprovedCV(): void {
    if (!this.analysisResult) return;

    const cvContent = this.analysisResult.improvedCV;
    const fileName = `Improved_CV_${this.targetDomain.replace(/\s+/g, '_')}`;

    switch (this.downloadFormat) {
      case 'pdf':
        this.downloadAsPDF(cvContent, fileName);
        break;
      case 'docx':
        this.downloadAsDOCX(cvContent, fileName);
        break;
      case 'txt':
        this.downloadAsTXT(cvContent, fileName);
        break;
    }
  }

  private downloadAsTXT(content: string, fileName: string): void {
    const blob = new Blob([content], { type: 'text/plain' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${fileName}.txt`;
    link.click();
    window.URL.revokeObjectURL(url);
  }

  private downloadAsPDF(content: string, fileName: string): void {
    // Simple PDF generation using browser print
    const printWindow = window.open('', '_blank');
    if (!printWindow) return;

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>${fileName}</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 40px auto;
            padding: 20px;
            color: #333;
          }
          h1, h2, h3 {
            color: #2c3e50;
            margin-top: 20px;
          }
          pre {
            white-space: pre-wrap;
            word-wrap: break-word;
            font-family: Arial, sans-serif;
          }
          @media print {
            body { margin: 0; padding: 20px; }
          }
        </style>
      </head>
      <body>
        <pre>${content}</pre>
        <script>
          window.onload = function() {
            window.print();
            setTimeout(function() { window.close(); }, 100);
          };
        </script>
      </body>
      </html>
    `;

    printWindow.document.write(htmlContent);
    printWindow.document.close();
  }

  private downloadAsDOCX(content: string, fileName: string): void {
    // Create a simple HTML document that Word can open
    const htmlContent = `
      <!DOCTYPE html>
      <html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word'>
      <head>
        <meta charset='utf-8'>
        <title>${fileName}</title>
        <style>
          body {
            font-family: Calibri, Arial, sans-serif;
            font-size: 11pt;
            line-height: 1.5;
          }
          h1 { font-size: 16pt; font-weight: bold; margin-top: 12pt; }
          h2 { font-size: 14pt; font-weight: bold; margin-top: 10pt; }
          p { margin: 6pt 0; }
        </style>
      </head>
      <body>
        <pre style="font-family: Calibri, Arial, sans-serif; white-space: pre-wrap;">${content}</pre>
      </body>
      </html>
    `;

    const blob = new Blob(['\ufeff', htmlContent], {
      type: 'application/msword'
    });

    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${fileName}.doc`;
    link.click();
    window.URL.revokeObjectURL(url);
  }

  startNew(): void {
    this.cvText = '';
    this.targetDomain = '';
    this.uploadedFileName = '';
    this.analysisResult = null;
    this.analysisComplete = false;
    this.errorMessage = '';
    this.activeTab = 'input';
  }

  goToSubscription(): void {
    this.router.navigate(['/SubscriptionPlans']);
  }
}
