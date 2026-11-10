import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

@Component({
  selector: 'app-skill-test-result',
  templateUrl: './skill-test-result.component.html',
  styleUrl: './skill-test-result.component.css'
})
export class SkillTestResultComponent implements OnInit {
  testId = 0;
  score = 0;
  testTitle = '';
  passed = false;

  constructor(private route: ActivatedRoute) {}

  ngOnInit(): void {
    this.testId = +this.route.snapshot.paramMap.get('id')!;
    this.score = +(this.route.snapshot.queryParamMap.get('score') ?? 0);
    const passedParam = this.route.snapshot.queryParamMap.get('passed');
    this.passed = passedParam !== null ? passedParam === 'true' : this.score >= 70;
    this.testTitle = this.route.snapshot.queryParamMap.get('title') ?? 'Skill Test';
  }
}
