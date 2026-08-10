/// Free-form answers gathered during onboarding, stored in
/// [UserProfile.habits] as `{id: 'yes'}` for opted-in habits.
class OnboardingHabit {
  const OnboardingHabit(this.id, this.label);

  final String id;
  final String label;
}

const List<OnboardingHabit> onboardingHabits = [
  OnboardingHabit('lights_off', 'I switch off unused lights'),
  OnboardingHabit('reusable_bottle', 'I carry a reusable bottle'),
  OnboardingHabit('recycling', 'I recycle waste at home'),
  OnboardingHabit('no_single_use_plastic', 'I avoid single-use plastic'),
  OnboardingHabit('shorter_showers', 'I take shorter showers'),
  OnboardingHabit('efficient_appliances', 'I use efficient appliances'),
];
