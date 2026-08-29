(() => {
  const panel = document.getElementById('panel');
  const params = new URLSearchParams(window.location.search);
  const prefilledEmail = params.get('email') || '';
  const requestedPlan = (params.get('plan') || 'pro').toLowerCase();

  const config = window.CHECKOUT_CONFIG;
  if (
    !config ||
    !config.supabaseUrl ||
    config.supabaseUrl.includes('YOUR_PROJECT')
  ) {
    panel.innerHTML =
      '<p class="error">Checkout is not configured. Copy <code>config.example.js</code> to <code>config.js</code>, or run <code>python3 checkout/serve.py</code>.</p>';
    return;
  }

  const supabase = window.supabase.createClient(
    config.supabaseUrl,
    config.supabaseAnonKey,
  );

  let selectedPlan =
    requestedPlan === 'elite' || requestedPlan === 'pro' ? requestedPlan : 'pro';
  let busy = false;

  function formatInr(paise) {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    }).format(paise / 100);
  }

  function escapeHtml(value) {
    return String(value)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
  }

  async function currentUser() {
    const { data } = await supabase.auth.getUser();
    return data.user;
  }

  function showError(message) {
    const existing = panel.querySelector('.error');
    if (existing) existing.remove();
    const p = document.createElement('p');
    p.className = 'error';
    p.textContent = message;
    panel.prepend(p);
  }

  function renderLogin() {
    panel.innerHTML = `
      <form class="card" id="login-form">
        <p>Use the email and password from the Medico app.</p>
        <label for="email">Email</label>
        <input id="email" type="email" autocomplete="email" required />
        <label for="password">Password</label>
        <input id="password" type="password" autocomplete="current-password" required />
        <button class="primary" type="submit">Sign in</button>
      </form>
    `;
    panel.querySelector('#email').value = prefilledEmail;

    panel.querySelector('#login-form').addEventListener('submit', async (event) => {
      event.preventDefault();
      const email = panel.querySelector('#email').value.trim();
      const password = panel.querySelector('#password').value;
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (error) {
        showError(error.message);
        return;
      }
      await renderApp();
    });
  }

  function renderPlans(user) {
    const plans = window.PAID_PLANS;
    const cards = Object.entries(plans)
      .map(([id, plan]) => {
        const selected = id === selectedPlan ? ' selected' : '';
        return `
          <div class="card${selected}">
            <button class="plan-pick" type="button" data-plan="${id}">
              <div class="row">
                <strong>${escapeHtml(plan.label)}</strong>
                <span class="price">${formatInr(plan.amountPaise)}</span>
              </div>
              <p class="muted">${escapeHtml(plan.tagline)} · ${escapeHtml(plan.periodLabel)}</p>
            </button>
          </div>
        `;
      })
      .join('');

    panel.innerHTML = `
      <p class="muted">Signed in as ${escapeHtml(user.email)}</p>
      ${cards}
      <button class="primary" id="pay" type="button">Pay with Razorpay</button>
      <button class="ghost" id="sign-out" type="button">Sign out</button>
    `;

    panel.querySelectorAll('[data-plan]').forEach((button) => {
      button.addEventListener('click', () => {
        selectedPlan = button.getAttribute('data-plan');
        renderPlans(user);
      });
    });

    panel.querySelector('#pay').addEventListener('click', () => startPay(user));
    panel.querySelector('#sign-out').addEventListener('click', async () => {
      await supabase.auth.signOut();
      renderLogin();
    });
  }

  function renderSuccess() {
    panel.innerHTML = `
      <div class="card">
        <p class="success">Payment received.</p>
        <p>
          Your plan should update within a few seconds. Reopen Medico and tap
          refresh on Profile if it still shows Free.
        </p>
        <p class="muted">You can close this tab.</p>
      </div>
    `;
  }

  async function startPay(user) {
    if (busy) return;
    busy = true;
    const payButton = panel.querySelector('#pay');
    if (payButton) {
      payButton.disabled = true;
      payButton.textContent = 'Opening Razorpay…';
    }

    const { data, error } = await supabase.functions.invoke(
      'create-razorpay-order',
      { body: { plan: selectedPlan } },
    );

    let invokeError = null;
    if (error) {
      invokeError = error.message || 'Could not start checkout.';
      try {
        const body = await error.context.json();
        if (body && body.error) invokeError = body.error;
      } catch {
        // Non-JSON error body from the gateway / undeployed function.
      }
    }

    if (invokeError || !data || !data.orderId) {
      busy = false;
      renderPlans(user);
      showError(invokeError || (data && data.error) || 'Could not start checkout.');
      return;
    }

    if (typeof window.Razorpay !== 'function') {
      busy = false;
      renderPlans(user);
      showError('Razorpay failed to load. Check your network and try again.');
      return;
    }

    const options = {
      key: data.keyId,
      amount: data.amount,
      currency: data.currency,
      name: data.name,
      description: data.description,
      order_id: data.orderId,
      prefill: { email: data.prefillEmail || user.email },
      theme: { color: '#0D7377' },
      handler() {
        busy = false;
        renderSuccess();
      },
      modal: {
        ondismiss() {
          busy = false;
          renderPlans(user);
        },
      },
    };

    const rzp = new window.Razorpay(options);
    rzp.on('payment.failed', () => {
      busy = false;
      renderPlans(user);
      showError('Payment failed. No charge was kept. You can try again.');
    });
    rzp.open();
  }

  async function renderApp() {
    const user = await currentUser();
    if (!user) {
      renderLogin();
      return;
    }
    renderPlans(user);
  }

  renderApp();
})();
