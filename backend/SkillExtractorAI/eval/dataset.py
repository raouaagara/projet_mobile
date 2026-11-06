"""Evaluation CVs (6 English, 6 French) with the skills a human expects, using eval/catalog.json.

Traps on purpose: JavaScript without Java, React Native without React, "tableau de bord"
(French for dashboard), "spring 2023", "go from prototype", "react quickly", single-letter C,
French phrasings, and two CVs where skills only appear as paraphrases (semantic model).
"""

CVS = [
    dict(
        id="en_1_fullstack",
        lang="en",
        expected=["JavaScript", "TypeScript", "Python", "React", "HTML", "CSS", "Node.js", "Django",
                  "PostgreSQL", "MongoDB", "Git", "Docker", "Jenkins", "React Native", "Microservices",
                  "AWS", "Kubernetes", "CI/CD", "Unit Testing", "SEO", "Web Development", "REST APIs",
                  "English", "French", "Databases"],
        text="""John Carter
Full Stack Developer — Boston, MA
john.carter@mail.com | +1 617 555 0199

SUMMARY
Full stack developer with 4 years of experience building web applications and REST APIs. I react quickly to production incidents and enjoy mentoring juniors.

SKILLS
Languages: JavaScript, TypeScript, Python
Frontend: React.js, HTML5, CSS3, Tailwind
Backend: Node.js, Express, Django
Databases: PostgreSQL, MongoDB
Tools: Git, Docker, Jenkins

EXPERIENCE
Senior Developer — Shopify (2022 - present)
• Built a React Native companion app used by 50k merchants.
• Designed microservices deployed on AWS with Kubernetes.
• Set up continuous integration pipelines and wrote unit tests with Jest.

Web Developer — Freelance (2020 - 2022)
• Delivered 20+ websites for small businesses, improving their search engine optimization.

EDUCATION
B.Sc. Computer Science — Northeastern University (2020)

LANGUAGES
English (native), French (intermediate)
""",
    ),
    dict(
        id="en_2_data",
        lang="en",
        expected=["Python", "SQL", "Machine Learning", "Deep Learning", "TensorFlow", "Power BI",
                  "Tableau", "Data Analysis", "English"],
        text="""Priya Sharma
Data Scientist

PROFILE
Data scientist passionate about turning raw data into business decisions.

TECHNICAL SKILLS
Python, R, SQL, Pandas, scikit-learn, TensorFlow
Machine learning, deep learning, statistical analysis
Dashboards: Power BI, Tableau

WORK EXPERIENCE
Data Scientist — Accenture (2021 - 2024)
• Trained neural networks to forecast demand across 300 stores.
• Built interactive dashboards and reports for executives.
• Cleaned and explored large datasets to find churn drivers.

Data Analyst Intern — Deloitte (2020)
• Automated Excel reports and wrote SQL queries on SQL Server.

EDUCATION
M.Sc. Data Science — University of Toronto

LANGUAGES
English, Hindi
""",
    ),
    dict(
        id="en_3_designer",
        lang="en",
        expected=["Figma", "Adobe Photoshop", "UI/UX Design", "Graphic Design", "Agile/Scrum", "English"],
        text="""Emma Wilson
Product Designer

ABOUT ME
I design simple, accessible digital products.

SKILLS
Figma, Adobe Photoshop, Illustrator
User research, wireframing, prototyping
Design systems, usability testing

EXPERIENCE
Product Designer — Spotify (2021 - present)
• Redesigned the onboarding flow, improving the user experience for 2M new users.
• Created high-fidelity mockups and interactive prototypes in Figma.
• Worked closely with engineers in an agile team using Scrum.

Graphic Designer — Studio Nova (2018 - 2021)
• Created brand identities, posters and social media visuals.

EDUCATION
BA Graphic Design — Parsons School of Design

LANGUAGES
English, Spanish
""",
    ),
    dict(
        id="en_4_mobile",
        lang="en",
        expected=["Flutter", "Dart", "Kotlin", "Swift", "Firebase", "REST APIs", "Git", "C", "C++",
                  "Android", "Mobile Development"],
        text="""Lucas Martin
Mobile Developer

SUMMARY
Mobile developer building apps for phones. In spring 2023 I joined a startup to go from prototype to production.

SKILLS
Flutter, Dart, Kotlin, Swift
Firebase, REST APIs, Git
C, C++

PROJECTS
• Food delivery app with Flutter and Firebase (10k downloads on Google Play).
• Offline-first Android app written in Kotlin.

EXPERIENCE
Mobile Engineer — Glovo (2023 - present)
• Shipped features to iOS and Android apps with a team of 6.
• Improved crash-free sessions to 99.8%.

EDUCATION
Software Engineering degree — ESPRIT (2023)
""",
    ),
    dict(
        id="en_5_pm",
        lang="en",
        expected=["Project Management", "Agile/Scrum", "Communication", "Databases", "English", "French"],
        text="""Sarah Johnson
Project Manager

PROFILE
Certified project manager with strong communication and leadership.

KEY SKILLS
Project management, Agile, Scrum, Jira
Stakeholder management, budgeting, risk management
Microsoft Excel, PowerPoint

EXPERIENCE
IT Project Manager — Capgemini (2019 - present)
• Led a team of 12 developers delivering a banking platform.
• Ran sprint planning and retrospectives.
• Coordinated the migration of the customer databases to the cloud.

EDUCATION
MBA — HEC Montreal

LANGUAGES
English, French
""",
    ),
    dict(
        id="en_6_paraphrases",
        lang="en",
        expected=["Mobile Development", "Machine Learning", "Android", "Project Management", "SEO"],
        text="""Tom Becker
Software Engineer

SUMMARY
Engineer who builds smartphone apps and teaches computers to learn from data.

EXPERIENCE
Software Engineer — Zalando (2021 - present)
• Created applications for iPhone and Android phones used by millions of shoppers.
• Built predictive models trained on historical sales data.
• Organized the team's sprints, deadlines and budget as the delivery lead.
• Improved how our pages rank in Google search results.

EDUCATION
B.Sc. Computer Science
""",
    ),
    dict(
        id="fr_1_fullstack",
        lang="fr",
        expected=["Java", "JavaScript", "PHP", "SQL", "Spring Boot", "Angular", "Laravel", "MySQL",
                  "MongoDB", "Git", "Docker", "Jenkins", "Linux", "REST APIs", "Microservices",
                  "Kubernetes", "Unit Testing", "CI/CD", "Web Development", "Databases", "French", "English"],
        text="""Amine Ben Salah
Développeur Full Stack — Tunis

PROFIL
Développeur passionné par la création d'applications web performantes. Je présente mes résultats sous forme de tableau de bord.

COMPÉTENCES TECHNIQUES
Langages : Java, JavaScript, PHP, SQL
Frameworks : Spring Boot, Angular, Laravel
Bases de données : MySQL, MongoDB
Outils : Git, Docker, Jenkins, Linux

EXPÉRIENCE PROFESSIONNELLE
Développeur Java — Vermeg (2022 - aujourd'hui)
• Conception et développement d'API REST sécurisées.
• Mise en place d'une architecture microservices avec Docker et Kubernetes.
• Écriture de tests unitaires et intégration continue avec Jenkins.

Stage — Sofrecom (2021)
• Développement d'un site e-commerce avec Laravel.

FORMATION
Diplôme d'ingénieur en informatique — ESPRIT (2022)

LANGUES
Français, Anglais, Arabe
""",
    ),
    dict(
        id="fr_2_data",
        lang="fr",
        expected=["Python", "SQL", "Power BI", "Machine Learning", "Deep Learning", "Data Analysis",
                  "TensorFlow", "French", "English"],
        text="""Sarra Trabelsi
Data Scientist

PROFIL
Ingénieure en science des données, spécialisée en apprentissage automatique.

COMPÉTENCES
Python, SQL, Power BI
Apprentissage automatique, apprentissage profond, traitement du langage naturel
Analyse de données, statistiques
TensorFlow, Pandas

EXPÉRIENCES
Data Scientist — Orange Tunisie (2021 - 2024)
• Développement de modèles de prédiction du churn des clients.
• Création de tableaux de bord interactifs pour la direction.
• Analyse des données de consommation de 2 millions d'abonnés.

FORMATION
Master en intelligence artificielle — ENSI

LANGUES
Français, Anglais
""",
    ),
    dict(
        id="fr_3_designer",
        lang="fr",
        expected=["Figma", "Adobe Photoshop", "UI/UX Design", "Graphic Design", "Teamwork",
                  "Agile/Scrum", "French", "English"],
        text="""Yasmine Gharbi
Designer UI/UX

À PROPOS
Designer créative, je conçois des interfaces simples et accessibles.

COMPÉTENCES
Figma, Adobe Photoshop, Illustrator
Conception d'interfaces, expérience utilisateur, maquettage
Design graphique, identité visuelle

EXPÉRIENCE
Designer UI/UX — Instadeep (2022 - aujourd'hui)
• Conception des parcours utilisateurs de l'application mobile.
• Réalisation de maquettes haute fidélité et de prototypes interactifs.
• Travail en équipe avec les développeurs en méthode agile.

FORMATION
Licence en design graphique — ISAMM

LANGUES
Français, Anglais
""",
    ),
    dict(
        id="fr_4_mobile",
        lang="fr",
        expected=["Flutter", "Dart", "Kotlin", "Firebase", "REST APIs", "Git", "C", "C++", "Android",
                  "Mobile Development", "Unit Testing", "French", "English"],
        text="""Mohamed Ali Jaziri
Développeur Mobile

PROFIL
Développeur d'applications pour smartphones Android et iOS depuis 3 ans.

COMPÉTENCES TECHNIQUES
Flutter, Dart, Kotlin
Firebase, API REST, Git
Langage C, C++

PROJETS ACADÉMIQUES
• Application de covoiturage réalisée en Flutter avec Firebase.
• Jeu 2D en C++.

EXPÉRIENCE
Stage de fin d'études — Proxym Group (2023)
• Développement de nouvelles fonctionnalités d'une application bancaire mobile.
• Tests unitaires et revue de code.

FORMATION
Ingénieur en génie logiciel — ESPRIT

LANGUES
Français, Anglais, Arabe
""",
    ),
    dict(
        id="fr_5_marketing",
        lang="fr",
        expected=["Digital Marketing", "SEO", "Content Writing", "Project Management", "French", "English"],
        text="""Ines Mansour
Chargée de marketing digital

PROFIL
Spécialiste du marketing numérique et de la création de contenu.

COMPÉTENCES
Marketing digital, référencement naturel (SEO)
Rédaction web, community management
Gestion de projet, Canva, Google Analytics

EXPÉRIENCE
Chargée de marketing — Jumia (2021 - aujourd'hui)
• Pilotage de campagnes publicitaires sur les réseaux sociaux.
• Optimisation du positionnement des pages dans les moteurs de recherche.
• Coordination d'une équipe de 4 rédacteurs.

FORMATION
Master en marketing — IHEC Carthage

LANGUES
Français, Anglais
""",
    ),
    dict(
        id="fr_6_paraphrases",
        lang="fr",
        expected=["Mobile Development", "Machine Learning", "Android", "Project Management", "SEO"],
        text="""Nour Hamdi
Ingénieure logiciel

PROFIL
Je crée des applications pour téléphones et j'entraîne des modèles prédictifs.

EXPÉRIENCE
Ingénieure logiciel — Talan (2022 - aujourd'hui)
• Création d'applications pour téléphones Android et iPhone.
• Entraînement de modèles prédictifs sur les données clients.
• Organisation des sprints, du planning et du budget de l'équipe.
• Amélioration du classement de nos pages dans les résultats de recherche Google.

FORMATION
Diplôme d'ingénieur — INSAT
""",
    ),
]
