#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { marked } = require('marked');

const ROOT = '/Users/lwblx/huapohen/agent/rea/doubao_input';
const mdPath = path.join(ROOT, 'reports/REPORT.md');
const templatePath = path.join(ROOT, 'scripts/report_template.html');
const outPath = path.join(ROOT, 'reports/report.html');
const screensPath = path.join(ROOT, 'reports/assets/screens.json');

let md = fs.readFileSync(mdPath, 'utf8');
// The hero already carries the title; drop the first H1.
md = md.replace(/^# .*\n/, '');
// Drop the leading metadata blockquote to avoid duplicating the hero.
md = md.replace(/^>\s*非官方.*\n>\s*分析日期.*\n>\s*复刻：.*\n>\s*本报告中的.*\n/, '');

const html = marked.parse(md, { gfm: true, breaks: false });
const screens = JSON.parse(fs.readFileSync(screensPath, 'utf8'));
const cloneScreensPath = path.join(ROOT, 'reports/assets/clones.json');
const cloneScreens = fs.existsSync(cloneScreensPath) ? JSON.parse(fs.readFileSync(cloneScreensPath, 'utf8')) : [];
const template = fs.readFileSync(templatePath, 'utf8');
const generated = new Date().toLocaleString('zh-CN', { hour12: false });
const out = template
  .replace('{{CONTENT}}', html)
  .replace('{{SCREENS}}', JSON.stringify(screens))
  .replace('{{CLONE_SCREENS}}', JSON.stringify(cloneScreens))
  .replace(/\{\{GENERATED\}\}/g, generated);

fs.writeFileSync(outPath, out);
console.log('wrote', outPath, out.length, 'bytes; screens', screens.length);
