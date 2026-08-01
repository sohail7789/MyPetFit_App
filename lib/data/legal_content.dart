/// One numbered clause in a legal document.
class LegalClause {
  final String heading;
  final String body;

  const LegalClause({required this.heading, required this.body});
}

/// Terms of Service — transcribed verbatim from the design
/// ("MyPetFit Account.dc.html", `TERMS`).
const List<LegalClause> termsOfService = [
  LegalClause(
    heading: '1. Acceptance of terms',
    body: 'By creating a MyPetFit account or using the app you agree to these '
        'terms. If you do not agree, please do not use the service. We may '
        'update these terms; continued use after an update means you accept '
        'the revised terms.',
  ),
  LegalClause(
    heading: '2. What MyPetFit is — and is not',
    body: 'MyPetFit provides a lifestyle-based wellness assessment and product '
        'recommendations for companion animals. It is not a veterinary service '
        'and does not provide diagnosis, treatment or emergency advice. Scores '
        'and report cards are informational. Always consult a licensed '
        'veterinarian for medical concerns.',
  ),
  LegalClause(
    heading: '3. Your account',
    body: 'You are responsible for the accuracy of the information you enter '
        'and for keeping your login credentials secure. You must be 18 or '
        'older to create an account. One account may manage multiple pet '
        'profiles.',
  ),
  LegalClause(
    heading: '4. Assessments and scores',
    body: 'The fitness score is computed from your questionnaire answers using '
        'the MyPetFit scoring index. Its quality depends on the honesty and '
        'accuracy of your answers. Retaking the assessment replaces the '
        'previous score; historical report cards remain in your profile.',
  ),
  LegalClause(
    heading: '5. Purchases and delivery',
    body: 'Product prices are shown in Indian rupees and include applicable '
        'taxes. Orders can be cancelled until they are dispatched. Returns are '
        'accepted within 7 days for unopened products; consumables cannot be '
        'returned once opened.',
  ),
  LegalClause(
    heading: '6. Acceptable use',
    body: 'You agree not to misuse the service, attempt to access other users\' '
        'data, reverse-engineer the scoring system, or use the platform to '
        'advertise third-party products without our written consent.',
  ),
  LegalClause(
    heading: '7. Liability',
    body: 'To the fullest extent permitted by law, MyPetFit is not liable for '
        'decisions made based on assessment results, or for indirect or '
        'consequential losses. Nothing in these terms limits liability that '
        'cannot be limited by law.',
  ),
  LegalClause(
    heading: '8. Contact',
    body: 'Questions about these terms: legal@mypetfit.app.',
  ),
];

/// Privacy Policy — transcribed verbatim from the design (`PRIVACY`).
const List<LegalClause> privacyPolicy = [
  LegalClause(
    heading: '1. What we collect',
    body: 'Account details (name, email, phone), pet profile details (name, '
        'breed, age, weight, microchip number if provided), your questionnaire '
        'answers, order and delivery details, and basic device analytics.',
  ),
  LegalClause(
    heading: '2. How we use it',
    body: "To compute your pet's fitness score, generate report cards, "
        'personalise product recommendations, fulfil orders, and improve the '
        'service. With your consent form, anonymised and aggregated data may '
        'be used for veterinary and clinical research and product development.',
  ),
  LegalClause(
    heading: '3. What we never do',
    body: "We never sell your personal information. Your pet's identity and "
        'your contact details are never published or shared with advertisers. '
        'Research datasets are anonymised and cannot be traced back to you or '
        'your pet.',
  ),
  LegalClause(
    heading: '4. Sharing',
    body: 'We share data only with delivery partners (name, address, phone — '
        'to deliver orders), payment processors (to process payments), and '
        'research partners (anonymised, aggregated data only, under contract).',
  ),
  LegalClause(
    heading: '5. Storage and security',
    body: 'Data is stored on servers located in India, encrypted in transit '
        'and at rest. Access is limited to staff who need it, under '
        'confidentiality obligations.',
  ),
  LegalClause(
    heading: '6. Your rights',
    body: 'You can export your data, correct it, or delete your account at any '
        'time from Account settings. Deletion permanently removes your profile '
        "and your pet's health history within 30 days; anonymised research "
        'data already aggregated cannot be recalled.',
  ),
  LegalClause(
    heading: '7. Retention',
    body: 'We keep your data while your account is active. Order records are '
        'retained as required by tax law even after account deletion.',
  ),
  LegalClause(
    heading: '8. Contact',
    body: 'Data questions or requests: privacy@mypetfit.app. You may also '
        'lodge a complaint with your local data protection authority.',
  ),
];
