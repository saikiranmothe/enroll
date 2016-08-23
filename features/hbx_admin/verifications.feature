Feature: Clear verifications
	As an HBX admin I want to be able to verify an enrollment for an enrollment

	Scenario: provide verification reason
		Given I am an hbx admin
		When I login and click on the families tab
		And I select an enrollment that reuires verification
		And I click on Documents
		And I select the specific verification type
		When I select Document in EnrollApp
		And click Complete
		#what do is the expected result