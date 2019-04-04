---
is_hidden: true
---

# GitLab Secure

Check your application for security vulnerabilities that may lead to unauthorized access,
data leaks, and denial of services. GitLab will perform static and dynamic tests on the
code of your application, looking for known flaws and report them in the merge request
so you can fix them before merging. Security teams can use dashboards to get a
high-level view on projects and groups, and start remediation processes when needed.

The following documentation relates to the DevOps **Secure** stage:

| Secure topics                                                                                   | Description                                                            |
|:------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------|
| [Container Scanning](../project/merge_requests/container_scanning.md) **[ULTIMATE]**            | Use Clair to scan docker images for known vulnerabilities.             |
| [Dependency Scanning](../project/merge_requests/dependency_scanning.md) **[ULTIMATE]**          | Analyze your dependencies for known vulnerabilities.                   |
| [Dynamic Application Security Testing (DAST)](../project/merge_requests/dast.md) **[ULTIMATE]** | Analyze running web applications for known vulnerabilities.            |
| [Group Security Dashboard](../group/security_dashboard/index.md) **[ULTIMATE]**                 | View vulnerabilities in all the projects in a group and its subgroups. |
| [License Management](../project/merge_requests/license_management.md) **[ULTIMATE]**            | Search your project's dependencies for their licenses.                 |
| [Project Security Dashboard](../project/security_dashboard.md) **[ULTIMATE]**                   | View the latest security reports for your project.                     |
| [Static Application Security Testing (SAST)](../project/merge_requests/sast.md) **[ULTIMATE]**  | Analyze source code for known vulnerabilities.                         |
