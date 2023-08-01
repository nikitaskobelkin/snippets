//  The LandingView is a custom UIView in an iOS app that serves as the landing page. It utilizes UIKit and RxSwift to create a dynamic and
//  responsive interface. The view includes various subviews organized using UIStackView. Reactive binding with the LandingViewModel keeps
//  the UI in sync with data changes, ensuring a smooth user experience. The view also handles interactions with hyperlinks and button
//  actions, implementing UITextViewDelegate and RxSwift's gestures and bindings. Overall, the LandingView provides an appealing and
//  interactive landing page using UIKit, RxSwift, and the LandingViewModel. 

//  The LandingView ensures Accessibility by supporting VoiceOver and VoiceControl, making buttons and legal text accessible to users with
//  disabilities. It optimizes interaction with hyperlinks for VoiceOver users, enhancing overall inclusivity and usability in the app.

class LandingView: UIView, UITextViewDelegate {
    private let disposeBag = DisposeBag()
    private let viewModel: LandingViewModel
    private var selectedsubscription: subscriptionType
    
    private lazy var scrollStackView = UIStackView(
        spacing: self.viewModel.styleSheet.spacing.large,
        arrangedSubviews: [
            self.stackView,
            self.legalStackView
        ]
    )
    
    private lazy var stackView = UIStackView(
        spacing: self.viewModel.styleSheet.spacing.xLarge,
        arrangedSubviews: [
            self.headerView,
            self.detailsView,
            self.subscriptionsStack,
            self.paymentInfoStackView
        ]
    )
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    private lazy var headerView: LandingHeaderView = {
        let header = LandingHeaderView(
            styleSheet: self.viewModel.styleSheet
        )
        header.translatesAutoresizingMaskIntoConstraints = false
        return header
    }()
    
    private lazy var detailsView: LandingDetailsView = {
        let detailView = LandingDetailsView(
            styleSheet: self.viewModel.styleSheet
        )
        detailView.translatesAutoresizingMaskIntoConstraints = false
        return detailView
    }()
    
    private lazy var buttonsStack = UIStackView(
        spacing: self.viewModel.styleSheet.spacing.small,
        arrangedSubviews: [
            self.continueButton,
            self.skipButton
        ]
    )
    
    private lazy var subscriptionsStack = UIStackView(
        spacing: self.viewModel.styleSheet.spacing.medium
    )
    
    private lazy var legalStackView = UIStackView(
        axis: .vertical,
        arrangedSubviews: [self.legalTextView]
    )
    
    private lazy var paymentInfoStackView = UIStackView(
        axis: .horizontal,
        distribution: .equalSpacing,
        arrangedSubviews: [
            self.paymentInfoView,
            self.editPaymentButton
        ]
    )
    
    private lazy var paymentInfoView: PaymentInfoView = {
        let paymentInfoView = PaymentInfoView(styleSheet: self.viewModel.styleSheet)
        paymentInfoView.translatesAutoresizingMaskIntoConstraints = false
        return paymentInfoView
    }()
    
    private lazy var editPaymentButton: LabelButton = {
        let button = LabelButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let attributes = self.viewModel.styleSheet.fonts.body
            .textColor(
                controlState: .normal,
                color: self.viewModel.styleSheet.colors.primary
            )
            .textColor(
                controlState: .highlighted,
                color: self.viewModel.styleSheet.colors.primary.lighterColor
            )
        button.setup(withAttributes: attributes)
        button.titleLabel.text = LocalizedString.editPaymentButton
        return button
    }()
    
    private lazy var legalTextView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .left
        let titleLabelAttributes = self.viewModel.styleSheet.fonts.body3
            .textColor(
                controlState: nil,
                color: self.viewModel.styleSheet.colors.mediumGrey
            )
        textView.setup(withAttributes: titleLabelAttributes)
        let linkFont = self.viewModel.styleSheet.fonts.body3Bold.textAttributes[NSAttributedString.Key.font] ??
        UIFont.boldSystemFont(ofSize: textView.font.pointSize)
        textView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: self.viewModel.styleSheet.colors.darkGrey,
            NSAttributedString.Key.font: linkFont,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        return textView
    }()
    
    private lazy var borderPinnedContainerView: UIView = {
        let stroke = UIView()
        stroke.translatesAutoresizingMaskIntoConstraints = false
        stroke.layer.borderColor = self.viewModel.styleSheet.colors.lightGrey.cgColor
        return stroke
    }()
    
    private lazy var pinnedButtonsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = self.viewModel.styleSheet.colors.white
        return view
    }()
    
    private lazy var continueButton: LabelButton = {
        let buttonView = LabelButton()
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        let attributes = self.viewModel.styleSheet.fonts.body1Bold
            .backgroundColor(controlState: .normal, color: self.viewModel.styleSheet.colors.mutedPrimary)
            .backgroundColor(controlState: .disabled, color: self.viewModel.styleSheet.colors.lightGrey)
            .textColor(controlState: .normal, color: self.viewModel.styleSheet.colors.white)
            .cornerRadius(self.viewModel.styleSheet.views.defaultCornerRadius)
        buttonView.setup(withAttributes: attributes)
        buttonView.contentView.layoutMargins = UIEdgeInsets(insetBy: self.viewModel.styleSheet.spacing.medium)
        buttonView.constrainToFillSuperview()
        return buttonView
    }()
    
    private lazy var skipButton: UIButton = {
        let buttonView = UIButton()
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        let attributes = self.viewModel.styleSheet.fonts.link
            .textColor(controlState: .normal, color: self.viewModel.styleSheet.colors.darkGrey)
        buttonView.setup(withAttributes: attributes)
        buttonView.setTitle(LocalizedString.noThanks, for: .normal)
        return buttonView
    }()
    
    private lazy var closeButton: UIButton = {
        let buttonView = UIButton(type: .close)
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        return buttonView
    }()
    
    init(viewModel: LandingViewModel) {
        self.viewModel = viewModel
        self.selectedsubscription = .ammualMember
        super.init(frame: CGRect.zero)
        self.setupViews()
        self.setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.backgroundColor = self.viewModel.styleSheet.colors.white
        self.addSubview(self.scrollView)
        self.addSubview(self.closeButton)
        self.addSubview(self.pinnedButtonsContainerView)
        self.pinnedButtonsContainerView.constrainToFillSuperview(direction: .horizontal)
        self.pinnedButtonsContainerView.addSubview(self.buttonsStack)
        self.pinnedButtonsContainerView.addSubview(self.borderPinnedContainerView)
        self.buttonsStack.constrainToFillSuperview(
            insets: UIEdgeInsets(
                horizontal: self.viewModel.styleSheet.spacing.standardRowHeight,
                vertical: self.viewModel.styleSheet.spacing.medium
            )
        )
        self.scrollView.constrainToFillSuperview()
        self.scrollView.addSubview(self.scrollStackView)
        
        self.scrollStackView.constrainToFillSuperview(
            insets: UIEdgeInsets(
                top: self.viewModel.styleSheet.spacing.standardRowHeight,
                left: 0,
                bottom: self.viewModel.styleSheet.spacing.standardRowHeight * 2 + self.viewModel.styleSheet.spacing.medium,
                right: 0
            )
        )
        
        let closeButtonSize = self.viewModel.styleSheet.spacing.xLarge
        self.closeButton.constraints(forSize: CGSize(width: closeButtonSize, height: closeButtonSize))
        NSLayoutConstraint.activate([
            self.scrollStackView.widthAnchor.constraint(
                equalTo: self.scrollView.widthAnchor,
                constant: -self.viewModel.styleSheet.spacing.xLarge
            ),
            self.stackView.leftAnchor.constraint(equalTo: self.scrollStackView.leftAnchor, constant: self.viewModel.styleSheet.spacing.xLarge),
            self.stackView.rightAnchor.constraint(equalTo: self.scrollStackView.rightAnchor, constant: -self.viewModel.styleSheet.spacing.xLarge),
            self.legalStackView.leftAnchor.constraint(equalTo: self.scrollStackView.leftAnchor, constant: self.viewModel.styleSheet.spacing.medium),
            self.legalStackView.rightAnchor.constraint(equalTo: self.scrollStackView.rightAnchor, constant: self.viewModel.styleSheet.spacing.medium),
            self.closeButton.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: self.viewModel.styleSheet.spacing.xLarge
            ),
            self.closeButton.rightAnchor.constraint(
                equalTo: self.rightAnchor,
                constant: -self.viewModel.styleSheet.spacing.xLarge
            ),
            self.pinnedButtonsContainerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.borderPinnedContainerView.widthAnchor.constraint(equalTo: self.pinnedButtonsContainerView.widthAnchor),
            self.borderPinnedContainerView.heightAnchor.constraint(equalToConstant: 1),
            self.borderPinnedContainerView.topAnchor.constraint(equalTo: self.pinnedButtonsContainerView.topAnchor)
        ])
    }
    
    private func setupBindings() {
        self.viewModel.subscriptionViewModels
            .filter({ !$0.isEmpty })
            .drive(onNext: { [weak self] viewModels in
                guard let self = self else { return }
                self.buildsubscriptionsStackView(subscriptionViewModels: viewModels)
             })
            .disposed(by: self.disposeBag)
        
        self.viewModel.continueIsDisabled
            .map({ !$0 })
            .drive(self.continueButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
        self.viewModel.paymentInfoIcon
            .drive(self.paymentInfoView.imageCardView.rx.image)
            .disposed(by: self.disposeBag)
        
        self.viewModel.paymentInfoIcon
            .map({ $0 == nil })
            .drive(self.paymentInfoView.imageCardView.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        self.viewModel.paymentInfo
            .drive(self.paymentInfoView.cardInfoLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        self.viewModel.showPaymentInfo
            .map({ !$0 })
            .drive(self.paymentInfoStackView.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        self.viewModel.legalAttibutedText
            .drive(self.legalTextView.rx.attributedText)
            .disposed(by: self.disposeBag)
        
        self.viewModel.continueButtonTitle
            .drive(self.continueButton.titleLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        let closeButtonAction = self.closeButton.rx.tapGesture()
            .when(.recognized)
            .mapToVoid()
            
        let skipButtonAction = self.skipButton.rx.tapGesture()
            .when(.recognized)
            .mapToVoid()
        
        Observable.merge(closeButtonAction, skipButtonAction)
            .bind(to: self.viewModel.dismissPage)
            .disposed(by: self.disposeBag)
        
        self.editPaymentButton.rx.tapGesture()
            .when(.recognized)
            .mapToVoid()
            .bind(to: self.viewModel.editPaymentButtonTapped)
            .disposed(by: self.disposeBag)

        self.continueButton.rx.tapGesture()
            .when(.recognized)
            .mapToVoid()
            .bind(to: self.viewModel.signupButtonInput)
            .disposed(by: self.disposeBag)
    }
    
    private func setupAccessibility() {
        self.rx.isVoiceOverRunning
            .drive(self.continueButton.rx.isAccessibilityElement)
            .disposed(by: self.disposeBag)
        
        self.rx.isVoiceOverRunning
            .drive(self.skipButton.rx.isAccessibilityElement)
            .disposed(by: self.disposeBag)
        
        self.rx.isVoiceOverRunning
            .drive(self.closeButton.rx.isAccessibilityElement)
            .disposed(by: self.disposeBag)
    }
    
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard UIApplication.shared.canOpenURL(URL) else { return false }
        self.viewModel.openURL.accept(URL)
        return false
    }
}

private extension LandingView {
    func buildsubscriptionsStackView(subscriptionViewModels: [subscriptionViewModel]) {
        self.subscriptionsStack.removeAllArrangedSubviews()
        subscriptionViewModels
            .compactMap({ [weak self] in
                guard let self = self else { return nil }
                let subscriptionView = subscriptionView(
                    styleSheet: self.viewModel.styleSheet,
                    viewModel: $0
                )
                subscriptionView.translatesAutoresizingMaskIntoConstraints = false
                subscriptionView.setupBinding()
                return subscriptionView
            })
            .forEach({
                self.subscriptionsStack.addArrangedSubview($0)
            })
    }
}
