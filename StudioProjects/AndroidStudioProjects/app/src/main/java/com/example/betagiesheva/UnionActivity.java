package com.example.betagiesheva;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;


import com.example.betagiesheva.Model.Person;

import java.util.ArrayList;

public class UnionActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_union);

        ImageButton backButton = findViewById(R.id.back_button);
        backButton.setOnClickListener(v -> finish());

        CardView cardChairman = findViewById(R.id.card_chairman);
        CardView cardSecretary = findViewById(R.id.card_secretary);
        CardView cardMember = findViewById(R.id.card_member);
        CardView cardAccountant = findViewById(R.id.card_accountant);
        CardView cardAVillage = findViewById(R.id.card_village_police);

        cardChairman.setOnClickListener(v -> showCustomDialog("Chairman"));
        cardSecretary.setOnClickListener(v -> showCustomDialog("Secretary"));
        cardMember.setOnClickListener(v -> showCustomDialog("Member"));
        cardAccountant.setOnClickListener(v -> showCustomDialog("Accountant"));
        cardAVillage.setOnClickListener(v -> showCustomDialog("Village"));
    }

    private void showCustomDialog(final String category) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        LayoutInflater inflater = (LayoutInflater) getSystemService(LAYOUT_INFLATER_SERVICE);
        View dialogView = inflater.inflate(R.layout.custom_dialog_union, null);
        builder.setView(dialogView);

        final AlertDialog dialog = builder.create();

        dialogView.findViewById(R.id.card1).setOnClickListener(v -> {
            ArrayList<Person> personList = new ArrayList<>();
            if ("Chairman".equals(category)) {
                personList.add(new Person("অধ্যাপক মোঃ নওয়াব হোসেন নয়ন", "ইউপি চেয়ারম্যান", "01723971641", "http://example.com/chairman1"));
                PersonActivity.TITLE = "ইউপি চেয়ারম্যান";
            } else if ("Secretary".equals(category)) {
                personList.add(new Person("শিশির চন্দ্র মিস্ত্রি", "প্রশাসনিক কর্মকর্তা", "01719562641", "http://example.com/secretary1"));
                PersonActivity.TITLE = "ইউপি প্রশাসনিক কর্মকর্তা";
            } else if ("Member".equals(category)) {
                personList.add(new Person("জনাব মোঃ নুরুল ইসলাম", "বিবিচিনি ইউপি, ১নং ওয়ার্ড", "01758674826", "01732335914"));
                personList.add(new Person("জনাব মোর্শেদ হাসান নয়ন", "বিবিচিনি ইউপি, ২নং ওয়ার্ড", "01730161246", ""));
                personList.add(new Person("জনাব মোঃ শাহাবুদ্দিন জসিম", "বিবিচিনি ইউপি, ৩নং ওয়ার্ড", "01723471091", ""));
                personList.add(new Person("জনাব সৈয়দ রিয়াজ হোসেন", "বিবিচিনি ইউপি, ৪নং ওয়ার্ড", "01711463458", ""));
                personList.add(new Person("জনাব মোঃ রিয়াজ সিকদার", "বিবিচিনি ইউপি, ৫নং ওয়ার্ড", "01716135470", ""));
                personList.add(new Person("জনাব মোঃ ইউসুফ আলী আকন", "বিবিচিনি ইউপি, ৬নং ওয়ার্ড", "01768663033", ""));
                personList.add(new Person("জনাব মোঃ মজিবুর রহমান", "বিবিচিনি ইউপি, ৭নং ওয়ার্ড", "01734604304", ""));
                personList.add(new Person("জনাব মোঃ রুহুল আমীন কালন", "বিবিচিনি ইউপি, ৮নং ওয়ার্ড", "01738197506", ""));
                personList.add(new Person("জনাব মোঃ মজিবর রহমান খন্দকার", "বিবিচিনি ইউপি, ৯নং ওয়ার্ড", "01710181714", ""));
                personList.add(new Person("মোসাঃ মাকসুদা বেগম", "বিবিচিনি ইউপি, ১,২,৩নং ওয়ার্ড", "01772342107", ""));
                personList.add(new Person("মোসাঃ শিমুলী বেগম", "বিবিচিনি ইউপি, ৪,৫,৬নং ওয়ার্ড", "01759071833", ""));
                personList.add(new Person("মোসাঃ জাকিয়া আক্তার", "বিবিচিনি ইউপি, ৭,৮,৯নং ওয়ার্ড", "01768907867", ""));
                PersonActivity.TITLE = "ইউপি মেম্বার";
            } else if ("Accountant".equals(category)) {
                personList.add(new Person("হাফিজা আক্তার", "হিসাব সহকারী কাম কম্পিউটার অপারেটর", "01725121935", ""));
                PersonActivity.TITLE = "ইউপি কম্পিউটার অপারেটর";
            } else if ("Village".equals(category)) {
                personList.add(new Person("মোঃ ফিরোজ আলম (মন্টু)", "দফাদার", "01718723495", ""));
                personList.add(new Person("মোঃ ইদ্রিস ফকির", "গ্রাম পুলিশ", "01792948284", ""));
                personList.add(new Person("মোঃ হাচান তালুকদার", "গ্রাম পুলিশ", "01749080994", ""));
                personList.add(new Person("মোঃ রুস্তুম হাওলাদার", "গ্রাম পুলিশ", "01748652471", ""));
                personList.add(new Person("মোঃ মিজানুর রহমান (শাহীন)", "গ্রাম পুলিশ", "01712948363", ""));
                personList.add(new Person("মোঃ আবু বক্কর সিদ্দিকী", "গ্রাম পুলিশ", "01728509891", ""));
                personList.add(new Person("গোবিন্দ চন্দ্র শীল", "গ্রাম পুলিশ", "01747499080", ""));
                personList.add(new Person("শহিদুল ইসলাম", "গ্রাম পুলিশ", "01742575211", ""));
                personList.add(new Person("মোঃ বেলাল হোসেন", "গ্রাম পুলিশ", "01755215529", ""));
                PersonActivity.TITLE = "গ্রাম পুলিশ";
            }
            navigateToViewActivity(personList);
            dialog.dismiss();
        });

        dialogView.findViewById(R.id.card2).setOnClickListener(v -> {
            ArrayList<Person> personList = new ArrayList<>();
            if ("Chairman".equals(category)) {
                personList.add(new Person("মোঃ হুমায়ুন কবির", "ইউপি চেয়ারম্যান", "01734249083", "http://example.com/chairman1"));
                PersonActivity.TITLE = "ইউপি চেয়ারম্যান";
            } else if ("Secretary".equals(category)) {
                personList.add(new Person("লিটন চন্দ্র সমাদ্দার", "ইউপি সচিব", "01750300067", "http://example.com/secretary1"));
                PersonActivity.TITLE = "ইউপি প্রশাসনিক কর্মকর্তা";
            } else if ("Member".equals(category)) {
                personList.add(new Person("মোসাঃ পারভিন আক্তার", "ইউনিয়ন পরিষদের মেম্বার", "01725439180", ""));
                personList.add(new Person("মোঃ হুমায়ুন কবির", "ইউপি চেয়ারম্যান", "+8801734249083", ""));
                personList.add(new Person("মোসাঃ জেসমিন আক্তার", "ইউনিয়ন পরিষদের মেম্বার", "01916120273", ""));
                personList.add(new Person("খাতুনা জান্নাত পাখী", "ইউনিয়ন পরিষদের মেম্বার", "+8801737179051", ""));
                personList.add(new Person("মোঃ জসিম উদ্দিন", "ইউনিয়ন পরিষদের মেম্বার", "01710261213", ""));
                personList.add(new Person("মোসাঃ কামরুন্নাহার হেপি", "ইউনিয়ন পরিষদের মেম্বার", "+8801724431358", ""));
                personList.add(new Person("মোঃ বশির আলম পলাশ", "ইউনিয়ন পরিষদের মেম্বার", "01714143989", ""));
                personList.add(new Person("মোঃ মাহমুদ সিকদার মনির", "ইউনিয়ন পরিষদের মেম্বার", "+8801715391723", ""));
                personList.add(new Person("মোঃ মিজানুর রহমান সুমন", "ইউনিয়ন পরিষদের মেম্বার", "+8801711231494", ""));
                personList.add(new Person("মোঃ মিজানুর রহমান তালুকদার", "ইউনিয়ন পরিষদের মেম্বার", "01714585610", ""));
                personList.add(new Person("মোঃ তাইজুল ইসলাম", "ইউনিয়ন পরিষদের মেম্বার", "01714767431", ""));
                personList.add(new Person("মোঃ কেনান সিকদার", "ইউনিয়ন পরিষদের মেম্বার", "+88017722240009", ""));
                personList.add(new Person("মোঃ মোস্তফা কামাল", "ইউনিয়ন পরিষদের মেম্বার", "+8801717407475", ""));
                PersonActivity.TITLE = "ইউপি মেম্বার";
            } else if ("Village".equals(category)) {
                personList.add(new Person("মোঃ হাফিজুল হক", "দফাদার", "01782112030", ""));
                personList.add(new Person("মোঃ শাহজাহান", "মহল্লাদার", "01793280969", ""));
                personList.add(new Person("মোঃ জালাল", "মহল্লাদার", "01771873974", ""));
                personList.add(new Person("মোঃ শাহআলম", "মহল্লাদার", "01756322685", ""));
                personList.add(new Person("মোঃ নজির", "মহল্লাদার", "01779473230", ""));
                personList.add(new Person("মো মকবুল হোসেন", "মহল্লাদার", "01704673979", ""));
                PersonActivity.TITLE = "গ্রাম পুলিশ";
            }
            navigateToViewActivity(personList);
            dialog.dismiss();
        });

        dialogView.findViewById(R.id.card3).setOnClickListener(v -> {
            ArrayList<Person> personList = new ArrayList<>();
            if ("Secretary".equals(category)) {
                personList.add(new Person("শৈলেন চন্দ্র রায়", "প্রশাসনিক কর্মকর্তা", "01732011475", "http://example.com/secretary1"));
                PersonActivity.TITLE = "ইউপি প্রশাসনিক কর্মকর্তা";
            } else if ("Member".equals(category)) {
                personList.add(new Person("জনাবা মোস: মুক্তা বেগম", "ইউনিয়ন পরিষদের মেম্বার", "01721188451", ""));
                personList.add(new Person("জনাবা শিউলী ডাকুয়া", "ইউনিয়ন পরিষদের মেম্বার", "01782404903", ""));
                personList.add(new Person("জনাবা মোসাঃ আলেয়া বেগম হিরা", "ইউনিয়ন পরিষদের মেম্বার", "01775475739", ""));
                personList.add(new Person("জনাব আবদুল সালাম আকন", "ইউনিয়ন পরিষদের মেম্বার", "01716701138", ""));
                personList.add(new Person("জনাব মোঃ আলতাফ হোসেন ফরাজী", "ইউনিয়ন পরিষদের মেম্বার", "01731183356", ""));
                personList.add(new Person("জনাব মোঃ হিরুন মিয়া", "ইউনিয়ন পরিষদের মেম্বার", "01713953069", ""));
                personList.add(new Person("জনাব মোঃ মাসুদ আলম", "ইউনিয়ন পরিষদের মেম্বার", "01729186760", ""));
                personList.add(new Person("জনাব মোঃ নাসির উদ্দিন তালুকদার", "ইউনিয়ন পরিষদের মেম্বার", "01723474847", ""));
                personList.add(new Person("জনাব মোঃ ছিদ্দিকুর রহমান", "ইউনিয়ন পরিষদের মেম্বার", "01712668883", ""));
                personList.add(new Person("মোঃ আলতাফ হোসেন", "ইউনিয়ন পরিষদের মেম্বার", "01746001321", ""));
                personList.add(new Person("জনাব আবদুল মাজেদ মৃধা", "ইউনিয়ন পরিষদের মেম্বার", "01794714978", ""));
                personList.add(new Person("জনাব মোঃ শফিকুল ইসলাম", "ইউনিয়ন পরিষদের মেম্বার", "0178856598", ""));
                PersonActivity.TITLE = "ইউপি মেম্বার";
            } else if ("Accountant".equals(category)) {
                personList.add(new Person("রাজিয়াতুন নেছা", "হিসাব সহকারী কাম কম্পিউটার অপারেটর", "01324452429", ""));
                PersonActivity.TITLE = "ইউপি কম্পিউটার অপারেটর";
            } else if ("Village".equals(category)) {
                personList.add(new Person("মোঃ মজিবর রহমান", "দফাদার", "01752173980", ""));
                personList.add(new Person("মোঃ কামাল হোসেন", "মহল্লাদার", "01766273766", ""));
                personList.add(new Person("মোঃ আফজাল হোসেন", "মহল্লাদার", "01712334663", ""));
                personList.add(new Person("মোঃ আল-আমিন", "মহল্লাদার", "01767768984", ""));
                personList.add(new Person("মোঃ আকবর হোসেন", "মহল্লাদার", "01739278073", ""));
                personList.add(new Person("আঃ মজিদ খলিফা", "মহল্লাদার", "01760009355", ""));
                personList.add(new Person("মোঃ মাসুম বিল্লাহ", "মহল্লাদার", "01728997267", ""));
                personList.add(new Person("মোঃ আসলাম হোসেন", "মহল্লাদার", "01629788637", ""));
                personList.add(new Person("মোঃ লিমন হোসেন", "মহল্লাদার", "01734635173", ""));
                personList.add(new Person("মোঃ খলিলুর রহমান", "মহল্লাদার", "0176151", ""));
                PersonActivity.TITLE = "গ্রাম পুলিশ";
            }
            navigateToViewActivity(personList);
            dialog.dismiss();
        });

        dialogView.findViewById(R.id.card4).setOnClickListener(v -> {
            ArrayList<Person> personList = new ArrayList<>();
            if ("Chairman".equals(category)) {
                personList.add(new Person("আলহাজ্ব জালাল গাজী", "ইউপি চেয়ারম্যান", "01763153860", "http://example.com/chairman1"));
                PersonActivity.TITLE = "ইউপি চেয়ারম্যান";
            } else if ("Secretary".equals(category)) {
                personList.add(new Person("সুব্রত চন্দ্র মিত্র", "প্রশাসনিক কর্মকর্তা", "01762792861", "http://example.com/secretary1"));
                PersonActivity.TITLE = "ইউপি প্রশাসনিক কর্মকর্তা";
            } else if ("Member".equals(category)) {
                personList.add(new Person("কুরসিয়া আক্তার", "ইউনিয়ন পরিষদের মেম্বার", "01870143700", ""));
                personList.add(new Person("জাহিদা পারভীন", "ইউনিয়ন পরিষদের মেম্বার", "01709859617", ""));
                personList.add(new Person("মোসাঃ সুরাইয়া খাদিজা", "ইউনিয়ন পরিষদের মেম্বার", "01711016924", ""));
                personList.add(new Person("মোঃ টিপু সুলতান", "ইউনিয়ন পরিষদের মেম্বার", "01719977473", ""));
                personList.add(new Person("মোঃ ফারুক হোসেন খোকন", "ইউনিয়ন পরিষদের মেম্বার", "01719636293", ""));
                personList.add(new Person("মোঃ শাহীন হোসেন হাওলাদার", "ইউনিয়ন পরিষদের মেম্বার", "01714852774", ""));
                personList.add(new Person("আল হাসিবুর রহমান", "ইউনিয়ন পরিষদের মেম্বার", "01723471096", ""));
                personList.add(new Person("মোঃ জাফর মোল্লা", "ইউনিয়ন পরিষদের মেম্বার", "01712459125", ""));
                personList.add(new Person("মোঃ শাহীন মৃধা", "ইউনিয়ন পরিষদের মেম্বার", "01760511278", ""));
                personList.add(new Person("মোঃ নজরুল ইসলাম", "ইউনিয়ন পরিষদের মেম্বার", "01736287570", ""));
                personList.add(new Person("মোঃ আঃ রাজ্জাক", "ইউনিয়ন পরিষদের মেম্বার", "01784634257", ""));
                personList.add(new Person("মোঃ আমিনুল ইসলাম", "ইউনিয়ন পরিষদের মেম্বার", "01981022498", ""));
                PersonActivity.TITLE = "ইউপি মেম্বার";
            } else if ("Accountant".equals(category)) {
                personList.add(new Person("রুবি আক্তার", "হিসাব সহকারী কাম কম্পিউটার অপারেটর", " 01856996666", ""));
                PersonActivity.TITLE = "ইউপি কম্পিউটার অপারেটর";
            } else if ("Village".equals(category)) {
                personList.add(new Person("তরুন দাস", "দফাদার", "01756879286", ""));
                personList.add(new Person("মো: আবুল কালাম", "গ্রাম পুলিশ", "01721328650", ""));
                personList.add(new Person("মোঃ ইব্রাহীম", "গ্রাম পুলিশ", "01756630093", ""));
                personList.add(new Person("মোঃ হারুন মিয়া", "গ্রাম পুলিশ", "01761704936", ""));
                personList.add(new Person("মোঃ নুর মোহম্মদ", "গ্রাম পুলিশ", "01775587105", ""));
                personList.add(new Person("সজল আকন", "মহল্লাদার", "01724443761", ""));
                personList.add(new Person("মোঃ আল আমিন", "মহল্লাদার", "01304878812", ""));
                personList.add(new Person("মোসাঃ সুরভী আক্তার", "মহল্লাদার", "01716032196", ""));
                personList.add(new Person("রহিমা বেগম", "মহল্লাদার", "01610503575", ""));
                PersonActivity.TITLE = "গ্রাম পুলিশ";
            }
            navigateToViewActivity(personList);
            dialog.dismiss();
        });

        dialogView.findViewById(R.id.card5).setOnClickListener(v -> {
            ArrayList<Person> personList = new ArrayList<>();
            if ("Chairman".equals(category)) {
                personList.add(new Person("সৈয়দ গোলাম রব", "ইউপি চেয়ারম্যান", "01716-227244", "http://example.com/chairman1"));
                PersonActivity.TITLE = "ইউপি চেয়ারম্যান";
            } else if ("Secretary".equals(category)) {
                personList.add(new Person("স্বপন চন্দ্র রায়", "প্রশাসনিক কর্মকর্তা", "01715-544680", "http://example.com/secretary1"));
                PersonActivity.TITLE = "ইউপি প্রশাসনিক কর্মকর্তা";
            } else if ("Member".equals(category)) {
                personList.add(new Person("কহিনুর বেগম", "ইউনিয়ন পরিষদের মেম্বার", "01773-539865", ""));
                personList.add(new Person("ছাহেরা বেগম", "ইউনিয়ন পরিষদের মেম্বার", "01712-276133", ""));
                personList.add(new Person("হাসি রানী", "ইউনিয়ন পরিষদের মেম্বার", "01783-5164607", ""));
                personList.add(new Person("মোঃ নাসির উদ্দিন খান", "ইউনিয়ন পরিষদের মেম্বার", "01715-279590", ""));
                personList.add(new Person("মোঃ আবদুর রাজ্জাক হোসেন", "ইউনিয়ন পরিষদের মেম্বার", "01714-560747", ""));
                personList.add(new Person("মোঃ বজলুর রহমান", "ইউনিয়ন পরিষদের মেম্বার", "01714-794224", ""));
                personList.add(new Person("মোঃ মনিরুজ্জামান", "ইউনিয়ন পরিষদের মেম্বার", "01758-054995", ""));
                personList.add(new Person("মোঃ খোকন খান", "ইউনিয়ন পরিষদের মেম্বার", "01716-756946", ""));
                personList.add(new Person("মোঃ আঃ মন্নান", "ইউনিয়ন পরিষদের মেম্বার", "01724-322045", ""));
                personList.add(new Person("সঞ্জয় মন্ডল", "ইউনিয়ন পরিষদের মেম্বার", "01721-736289", ""));
                personList.add(new Person("মোঃ হামিদ খান ভাষানী", "ইউনিয়ন পরিষদের মেম্বার", "01787-820411", ""));
                personList.add(new Person("বাদল চক্রবর্তী", "ইউনিয়ন পরিষদের মেম্বার", "01724-768833", ""));
                PersonActivity.TITLE = "ইউপি মেম্বার";
            } else if ("Accountant".equals(category)) {
                personList.add(new Person("উর্মি আক্তার", "হিসাব সহকারী কাম কম্পিউটার অপারেটর", "01720-435023", ""));
                PersonActivity.TITLE = "ইউপি কম্পিউটার অপারেটর";
            } else if ("Village".equals(category)) {
                personList.add(new Person("মোঃ ইলিয়াস হোসেন", "দফাদার", "01734-348199", ""));
                personList.add(new Person("মোঃ মজিবুল হক", "গ্রাম পুলিশ", "01724-769251", ""));
                personList.add(new Person("রাছেল মিয়া", "গ্রাম পুলিশ", "01951-197261", ""));
                personList.add(new Person("মো: সবুজ", "গ্রাম পুলিশ", "01716-513900", ""));
                personList.add(new Person("মোঃ আঃ খালেক মিয়া", "গ্রাম পুলিশ", "01990-495480", ""));
                personList.add(new Person("মোঃ সোহাগ মিয়া", "গ্রাম পুলিশ", "01762-445272", ""));
                personList.add(new Person("মোঃ শাহজাহান", "গ্রাম পুলিশ", "01933-775291", ""));
                personList.add(new Person("মোঃ রুস্তুম আলী", "গ্রাম পুলিশ", "01721-652894", ""));
                personList.add(new Person("গণপতি ঢাকী", "গ্রাম পুলিশ", "01747-049757", ""));
                PersonActivity.TITLE = "গ্রাম পুলিশ";
            }
            navigateToViewActivity(personList);
            dialog.dismiss();
        });

        dialogView.findViewById(R.id.card6).setOnClickListener(v -> {
            ArrayList<Person> personList = new ArrayList<>();
            if ("Chairman".equals(category)) {
                personList.add(new Person("মো: সালাউদ্দিন মাহমুদ", "ইউপি চেয়ারম্যান", "01788888284", "http://example.com/chairman1"));
                PersonActivity.TITLE = "ইউপি চেয়ারম্যান";
            } else if ("Member".equals(category)) {
                personList.add(new Person("মোঃ হারুন অর রশিদ", "ইউনিয়ন পরিষদের মেম্বার", "01716643912", "01732335914"));
                personList.add(new Person("মোঃ শামীম হোসাইন", "ইউনিয়ন পরিষদের মেম্বার", "01723455047", ""));
                personList.add(new Person("মোঃ বেলাল হোসেন", "ইউনিয়ন পরিষদের মেম্বার", "01745426988", ""));
                personList.add(new Person("মোঃ সোহেল রানা", "ইউনিয়ন পরিষদের মেম্বার", "01735695215", ""));
                personList.add(new Person("মোসাঃ কহিনুর বেগম", "ইউনিয়ন পরিষদের মেম্বার", "01718746115", ""));
                personList.add(new Person("মোঃ মতিয়ার রহমান", "ইউনিয়ন পরিষদের মেম্বার", "01720901561", ""));
                personList.add(new Person("রিনা গাজি", "ইউনিয়ন পরিষদের মেম্বার", "017350111110", ""));
                personList.add(new Person("মোঃ আবুল হোসেন গাজি", "ইউনিয়ন পরিষদের মেম্বার", "017168132506", ""));
                personList.add(new Person("মোঃ কামাল হোসেন", "ইউনিয়ন পরিষদের মেম্বার", "01719564438", ""));
                personList.add(new Person("সুমন কুমার রায়", "ইউনিয়ন পরিষদের মেম্বার", "01714531243", ""));
                PersonActivity.TITLE = "ইউপি মেম্বার";
            } else if ("Village".equals(category)) {
                personList.add(new Person("বিধান চন্দ্র সরকার", "দফাদার", "01716-664577", ""));
                personList.add(new Person("মোঃ জাফর মিযা", "গ্রাম পুলিশ", "01722-168913", ""));
                personList.add(new Person("মোঃ রাজ্জাক মিয়া", "গ্রাম পুলিশ", "01937-322687", ""));
                personList.add(new Person("মোঃ খোকন মিয়া", "গ্রাম পুলিশ", "01739-846865", ""));
                personList.add(new Person("মোঃ শাহ আলম হাওলাদার", "গ্রাম পুলিশ", "01937-001223", ""));
                personList.add(new Person("মোঃ শাহীন মিয়া", "গ্রাম পুলিশ", "01725-487078", ""));
                personList.add(new Person("মোঃ হাবিবুর রহমান", "গ্রাম পুলিশ", "01729-647381", ""));
                personList.add(new Person("মোঃ দুলাল মিয়া", "গ্রাম পুলিশ", "01715-786409", ""));
                personList.add(new Person("মোঃ মোখলেসুর রহমান", "গ্রাম পুলিশ", "01731-188921", ""));
                PersonActivity.TITLE = "গ্রাম পুলিশ";
            }
            navigateToViewActivity(personList);
            dialog.dismiss();
        });

        dialog.show();
    }

    private void navigateToViewActivity(ArrayList<Person> personList) {
        Intent intent = new Intent(this, PersonActivity.class);
        intent.putExtra("personList", personList);
        startActivity(intent);
    }
}