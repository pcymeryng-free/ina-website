<?php
/**
 * INA Website — contact.php
 *
 * Handles the contact.html form directly on Bluehost, with PHP's
 * built-in mail() function — which hands the message straight to the
 * same local mail server (Exim) that already runs the info@inaai.co
 * mailbox. No external service, no Vercel, no SMTP credentials, no
 * environment variables to configure anywhere.
 *
 * Lives at the SITE ROOT on Bluehost (next to contact.html, index.html,
 * etc.) — NOT inside the api/ folder (that folder stays Vercel-only,
 * for api/analyze-project.js, which needs Node.js and cannot run on
 * Bluehost's PHP-only shared hosting).
 *
 * NOTE on submission style — this used to be called via fetch() from
 * assets/script.js, with this file replying in JSON. Switched to a plain
 * native <form method="POST" action="/contact.php"> submission instead
 * (see contact.html) because Bluehost's WAF has a "Human Presence Check"
 * (Imunify360 rule 33355) that intercepts POSTs it isn't sure are from a
 * real browser and replies with a small HTML/JS challenge page (sets a
 * "humans_NNNNN" cookie, then reloads) instead of forwarding the request
 * to this script at all. A real browser page navigation runs that
 * challenge script and passes it automatically; fetch() never executes
 * the returned script, so every AJAX submission silently died against
 * that wall forever. A native form POST is what actually gets through.
 *
 * Because of that, this script now replies with a redirect back to
 * contact.html (?sent=1 / ?error=...) instead of JSON — there's no more
 * JS on the other end to parse a JSON body.
 */

function ina_contact_clean($value) {
    $value = is_string($value) ? $value : '';
    $value = strip_tags($value);
    return trim($value);
}

function ina_contact_redirect($query) {
    header('Location: /contact.html?' . $query);
    exit;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(405);
    echo json_encode(array('error' => 'Method not allowed'));
    exit;
}

// Native form submissions land in $_POST. The json_decode() fallback is
// kept only in case anything ever posts JSON here again in the future.
$input = $_POST;
if (empty($input)) {
    $decoded = json_decode(file_get_contents('php://input'), true);
    if (is_array($decoded)) {
        $input = $decoded;
    }
}

$name = ina_contact_clean(isset($input['name']) ? $input['name'] : '');
$org = ina_contact_clean(isset($input['org']) ? $input['org'] : '');
$type = ina_contact_clean(isset($input['type']) ? $input['type'] : '');
$email = ina_contact_clean(isset($input['email']) ? $input['email'] : '');
$message = ina_contact_clean(isset($input['message']) ? $input['message'] : '');
// Honeypot: a hidden field real visitors never fill in (see the hidden
// "Reference" field in contact.html, id/name="hp_ref"). If a bot filled
// it in, silently pretend success instead of sending anything.
$honeypot = ina_contact_clean(isset($input['hp_ref']) ? $input['hp_ref'] : '');

if ($honeypot !== '') {
    ina_contact_redirect('sent=1');
}

if ($name === '' || $org === '' || $email === '' || $message === '') {
    ina_contact_redirect('error=validation');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    ina_contact_redirect('error=email');
}

$messageLength = function_exists('mb_strlen') ? mb_strlen($message) : strlen($message);
if ($messageLength > 8000) {
    ina_contact_redirect('error=length');
}

$to = 'info@inaai.co';
$subject = 'Advisory Request — ' . ($org !== '' ? $org : $name);
// mail() subjects with non-ASCII characters (like the em dash above)
// need MIME encoding or some mail clients show mangled text.
$encodedSubject = '=?UTF-8?B?' . base64_encode($subject) . '?=';

$bodyLines = array();
$bodyLines[] = 'New advisory request from the INA website contact form.';
$bodyLines[] = '';
$bodyLines[] = 'Name: ' . $name;
$bodyLines[] = 'Organization: ' . $org;
$bodyLines[] = 'Type: ' . ($type !== '' ? $type : '—');
$bodyLines[] = 'Email: ' . $email;
$bodyLines[] = '';
$bodyLines[] = 'Message:';
$bodyLines[] = $message;
$body = implode("\r\n", $bodyLines);

// From stays on the site's own domain (mail servers trust that more
// than an arbitrary visitor-supplied From address); Reply-To is the
// visitor's own address so Pablo can just hit "Reply" in Roundcube
// and it goes straight to them, not back to info@inaai.co.
$fromName = '=?UTF-8?B?' . base64_encode('INA Website') . '?=';
$replyToName = '=?UTF-8?B?' . base64_encode($name) . '?=';

$headers = array();
$headers[] = 'From: ' . $fromName . ' <info@inaai.co>';
$headers[] = 'Reply-To: ' . $replyToName . ' <' . $email . '>';
$headers[] = 'MIME-Version: 1.0';
$headers[] = 'Content-Type: text/plain; charset=UTF-8';
$headers[] = 'X-Mailer: PHP/' . phpversion();

// Envelope sender (-f): some cPanel/Exim setups reject or flag mail()
// calls that don't set this to a real local mailbox, treating it as a
// forged/anonymous sender otherwise.
error_clear_last();
$sent = mail($to, $encodedSubject, $body, implode("\r\n", $headers), '-finfo@inaai.co');

if ($sent) {
    ina_contact_redirect('sent=1');
} else {
    $lastError = error_get_last();
    $detail = $lastError ? $lastError['message'] : 'mail() returned false, no PHP error captured.';
    ina_contact_redirect('error=mail&detail=' . rawurlencode($detail));
}
